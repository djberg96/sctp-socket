#!/usr/bin/env ruby
#
# Multi-Stream Chat Server Example
#
# This example demonstrates SCTP's unique multi-streaming capabilities
# by implementing a chat server that uses different streams for different
# types of communication:
#
# Stream 0: System messages (reliable, ordered)
# Stream 1: Chat messages (reliable, ordered)
# Stream 2: File transfers (reliable, ordered)
# Stream 3: Presence updates (unreliable, can be dropped if old)
# Stream 4: Typing indicators (unreliable, latest only)
#
# Usage: ruby multi_stream_chat_server.rb

require 'sctp/socket'
require 'sctp/server'
require 'json'
require 'thread'

class MultiStreamChatServer
  # Stream definitions
  SYSTEM_STREAM = 0
  CHAT_STREAM = 1
  FILE_STREAM = 2
  PRESENCE_STREAM = 3
  TYPING_STREAM = 4

  def initialize(addresses = ['1.1.1.1', '1.1.1.2'], port = 62324)
    @addresses = addresses
    @port = port
    @clients = {}
    @rooms = { 'general' => [] }
    @mutex = Mutex.new
    @running = true

    puts "🚀 Starting Multi-Stream SCTP Chat Server"
    puts "📡 Listening on: #{@addresses.join(', ')}:#{@port}"
    puts "🔀 Using #{stream_names.length} streams for different message types"
    puts "🏠 Multi-homed server for fault tolerance"
  end

  def start
    # Use SCTP::Server in one-to-many mode for efficient multi-client handling
    @server = SCTP::Server.new(@addresses, @port,
      one_to_one: false,  # Use one-to-many mode
      init_msg: {
        output_streams: 5,    # We use 5 different streams
        input_streams: 5,     # Accept 5 streams from clients
        max_attempts: 3,
        max_init_timeout: 5000
      },
      subscriptions: {
        data_io: true,
        association: true,
        address: true,
        send_failure: true,
        peer_error: true,
        shutdown: true,
        partial_delivery: true
      }
    )

    puts "✅ Server started successfully!"
    puts "📍 Server address: #{@server.addr.join(', ')}:#{@server.local_port}"
    puts "💡 Connect with: ruby examples/multi_stream_chat_client.rb"
    puts "🌐 Multi-homing: Client can connect to either IP for redundancy"
    puts "📊 Stream Layout:"
    stream_names.each_with_index do |name, idx|
      puts "   Stream #{idx}: #{name}"
    end
    puts

    message_loop
  rescue => e
    puts "❌ Server error: #{e.message}"
    puts e.backtrace
  ensure
    cleanup
  end

  def stop
    @running = false
    @server&.close
  end

  private

  def message_loop
    puts "🔄 Starting message processing loop..."

    while @running
      begin
        # Receive message from any connected client using SCTP::Server
        info = @server.recvmsg
        next unless info

        # Handle notifications vs actual messages
        if info.notification
          handle_notification(info)
          next
        end

        message = info.message
        next unless message

        # Extract client info from association ID
        association_id = info.association_id
        client_id = "client_#{association_id}"
        stream = info.stream || 0

        # Register new client if we haven't seen them
        unless @clients[client_id]
          register_new_client(client_id, association_id)
        end

        # Parse and handle the message
        begin
          data = JSON.parse(message)
          puts "� [Stream #{stream}] #{client_id}: #{data['action'] || data['type'] || 'unknown'}"

          case stream
          when SYSTEM_STREAM
            handle_system_message(client_id, data)
          when CHAT_STREAM
            handle_chat_message(client_id, data)
          when FILE_STREAM
            handle_file_message(client_id, data)
          when PRESENCE_STREAM
            handle_presence_message(client_id, data)
          when TYPING_STREAM
            handle_typing_message(client_id, data)
          else
            puts "⚠️  Unknown stream #{stream} from #{client_id}"
          end
        rescue JSON::ParserError => e
          puts "❌ Invalid JSON from #{client_id}: #{e.message}"
        end

      rescue => e
        puts "❌ Message loop error: #{e.message}"
        break if !@running
        sleep(0.1)
      end
    end
  end

  def handle_notification(info)
    notification = info.notification
    
    case notification.type
    when 32769  # SCTP_ASSOC_CHANGE
      if notification.info == "comm up"
        puts "🔗 New association established: #{notification.association_id}"
      elsif notification.info == "shutdown complete"
        puts "👋 Association #{notification.association_id} shutdown"
        disconnect_client("client_#{notification.association_id}")
      end
    when 32770  # SCTP_PEER_ADDR_CHANGE
      puts "� Peer address change for association #{notification.association_id}: #{notification.ip_address}"
    when 32773  # SCTP_SHUTDOWN_EVENT
      puts "🛑 Shutdown event for association #{notification.association_id}"
    else
      puts "📋 Notification type #{notification.type}: #{notification.info rescue 'unknown'}"
    end
  end

  def register_new_client(client_id, association_id)
    @mutex.synchronize do
      @clients[client_id] = {
        association_id: association_id,
        username: nil,
        room: 'general',
        last_seen: Time.now
      }
      @rooms['general'] << client_id
    end

    puts "🔗 New client connected: #{client_id} (association: #{association_id})"

    # Send welcome message on system stream
    send_to_client(client_id, {
      type: 'welcome',
      message: 'Welcome to Multi-Stream SCTP Chat!',
      server_features: stream_descriptions,
      timestamp: Time.now.to_f
    }, SYSTEM_STREAM)
  end

  def handle_system_message(client_id, data)
    case data['action']
    when 'set_username'
      old_username = @clients[client_id][:username]
      @clients[client_id][:username] = data['username']

      broadcast_to_room(@clients[client_id][:room], {
        type: 'user_joined',
        username: data['username'],
        old_username: old_username,
        timestamp: Time.now.to_f
      }, SYSTEM_STREAM, exclude: client_id)

    when 'join_room'
      old_room = @clients[client_id][:room]
      new_room = data['room']

      # Remove from old room
      @rooms[old_room]&.delete(client_id)

      # Add to new room
      @rooms[new_room] ||= []
      @rooms[new_room] << client_id
      @clients[client_id][:room] = new_room

      send_to_client(client_id, {
        type: 'room_changed',
        old_room: old_room,
        new_room: new_room,
        timestamp: Time.now.to_f
      }, SYSTEM_STREAM)
    end
  end

  def handle_chat_message(client_id, data)
    username = @clients[client_id][:username] || client_id
    room = @clients[client_id][:room]

    message = {
      type: 'chat_message',
      username: username,
      message: data['message'],
      room: room,
      timestamp: Time.now.to_f
    }

    broadcast_to_room(room, message, CHAT_STREAM, exclude: client_id)
    puts "💬 [#{room}] #{username}: #{data['message']}"
  end

  def handle_file_message(client_id, data)
    username = @clients[client_id][:username] || client_id
    room = @clients[client_id][:room]

    case data['action']
    when 'file_start'
      puts "📁 #{username} starting file transfer: #{data['filename']}"
      broadcast_to_room(room, {
        type: 'file_transfer_start',
        username: username,
        filename: data['filename'],
        size: data['size'],
        timestamp: Time.now.to_f
      }, FILE_STREAM, exclude: client_id)

    when 'file_chunk'
      # In a real implementation, you'd handle file chunks
      puts "📦 #{username} sent file chunk #{data['chunk_num']}/#{data['total_chunks']}"

    when 'file_complete'
      puts "✅ #{username} completed file transfer: #{data['filename']}"
      broadcast_to_room(room, {
        type: 'file_transfer_complete',
        username: username,
        filename: data['filename'],
        timestamp: Time.now.to_f
      }, FILE_STREAM, exclude: client_id)
    end
  end

  def handle_presence_message(client_id, data)
    @clients[client_id][:last_seen] = Time.now
    username = @clients[client_id][:username] || client_id
    room = @clients[client_id][:room]

    # Presence updates are sent unreliably - if they get lost, that's OK
    # because we'll get another one soon
    broadcast_to_room(room, {
      type: 'presence_update',
      username: username,
      status: data['status'],
      timestamp: Time.now.to_f
    }, PRESENCE_STREAM, exclude: client_id, reliable: false)
  end

  def handle_typing_message(client_id, data)
    username = @clients[client_id][:username] || client_id
    room = @clients[client_id][:room]

    # Typing indicators are unreliable and can be dropped
    # Only the latest state matters
    broadcast_to_room(room, {
      type: 'typing_indicator',
      username: username,
      typing: data['typing'],
      timestamp: Time.now.to_f
    }, TYPING_STREAM, exclude: client_id, reliable: false)
  end

  def send_to_client(client_id, message, stream, reliable: true)
    return unless @clients[client_id]

    begin
      association_id = @clients[client_id][:association_id]
      options = {
        association_id: association_id,
        stream: stream
      }

      # For unreliable streams, set appropriate flags
      unless reliable
        options[:flags] = SCTP::Socket::SCTP_UNORDERED
      end

      @server.sendmsg(message.to_json, **options)
    rescue => e
      puts "❌ Failed to send to #{client_id}: #{e.message}"
      disconnect_client(client_id)
    end
  end

  def broadcast_to_room(room, message, stream, exclude: nil, reliable: true)
    @mutex.synchronize do
      (@rooms[room] || []).each do |client_id|
        next if client_id == exclude
        send_to_client(client_id, message, stream, reliable: reliable)
      end
    end
  end

  def disconnect_client(client_id)
    @mutex.synchronize do
      client = @clients[client_id]
      return unless client

      # Remove from room
      room = client[:room]
      @rooms[room]&.delete(client_id)

      # Notify others
      if client[:username]
        broadcast_to_room(room, {
          type: 'user_left',
          username: client[:username],
          timestamp: Time.now.to_f
        }, SYSTEM_STREAM)
      end

      # Remove client (no individual socket to close in one-to-many mode)
      @clients.delete(client_id)
      puts "👋 Client disconnected: #{client_id}"
    end
  end

  def cleanup
    puts "\n🧹 Shutting down server..."

    @mutex.synchronize do
      @clients.each do |client_id, client|
        begin
          send_to_client(client_id, {
            type: 'server_shutdown',
            message: 'Server is shutting down',
            timestamp: Time.now.to_f
          }, SYSTEM_STREAM)
        rescue
          # Best effort cleanup
        end
      end
    end

    @server&.close
    puts "✅ Server shutdown complete"
  end

  def stream_names
    [
      'System Messages',
      'Chat Messages',
      'File Transfers',
      'Presence Updates',
      'Typing Indicators'
    ]
  end

  def stream_descriptions
    {
      SYSTEM_STREAM => 'System messages (reliable, ordered)',
      CHAT_STREAM => 'Chat messages (reliable, ordered)',
      FILE_STREAM => 'File transfers (reliable, ordered)',
      PRESENCE_STREAM => 'Presence updates (unreliable, can be dropped)',
      TYPING_STREAM => 'Typing indicators (unreliable, latest only)'
    }
  end
end

# Handle graceful shutdown
server = nil
trap('INT') do
  puts "\n🛑 Received interrupt signal"
  server&.stop
  exit(0)
end

trap('TERM') do
  puts "\n🛑 Received terminate signal"
  server&.stop
  exit(0)
end

# Start the server
if __FILE__ == $0
  addresses = ARGV.empty? ? ['1.1.1.1', '1.1.1.2'] : ARGV
  server = MultiStreamChatServer.new(addresses)
  server.start
end
