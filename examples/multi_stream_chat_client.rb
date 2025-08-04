#!/usr/bin/env ruby
#
# Multi-Stream Chat Client Example
#
# This client demonstrates how to use SCTP's multi-streaming capabilities
# by sending different types of messages on different streams.
#
# Usage: ruby multi_stream_chat_client.rb [server_addresses]

require 'sctp/socket'
require 'json'
require 'thread'
require 'io/console'

class MultiStreamChatClient
  # Stream definitions (must match server)
  SYSTEM_STREAM = 0
  CHAT_STREAM = 1
  FILE_STREAM = 2
  PRESENCE_STREAM = 3
  TYPING_STREAM = 4

  def initialize(server_addresses = ['1.1.1.1', '1.1.1.2'], port = 62324)
    @server_addresses = server_addresses
    @port = port
    @username = nil
    @current_room = 'general'
    @socket = nil
    @running = false
    @last_typing_time = 0
    @typing_sent = false
  end

  def connect
    puts "🔗 Connecting to SCTP chat server at #{@server_addresses}:#{@port}"

    @socket = SCTP::Socket.new

    # Configure multi-streaming
    @socket.set_initmsg(
      output_streams: 5,
      input_streams: 5,
      max_attempts: 3,
      max_init_timeout: 5000
    )

    # Subscribe to events
    @socket.subscribe(
      data_io: true,
      association: true,
      address: true,
      send_failure: true
    )

    # Connect to server
    @socket.connectx(addresses: @server_addresses, port: @port)

    puts "✅ Connected successfully!"
    @running = true

    # Start message receiver thread
    @receiver_thread = Thread.new { message_receiver }

    # Start presence updater thread
    @presence_thread = Thread.new { presence_updater }

    # Get username
    setup_user

    # Start main interaction loop
    main_loop

  rescue => e
    puts "❌ Connection failed: #{e.message}"
  ensure
    disconnect
  end

  private

  def setup_user
    loop do
      print "👤 Enter your username: "
      username = gets.chomp.strip

      if username.length > 0
        @username = username
        send_message({
          action: 'set_username',
          username: @username,
          message: @username
        }, SYSTEM_STREAM)
        break
      else
        puts "❌ Username cannot be empty"
      end
    end
  end

  def main_loop
    puts "\n🎉 Welcome to Multi-Stream SCTP Chat, #{@username}!"
    puts "💡 Commands:"
    puts "   /help           - Show this help"
    puts "   /join <room>    - Join a chat room"
    puts "   /file <path>    - Send a file (simulated)"
    puts "   /status <msg>   - Set presence status"
    puts "   /quit           - Exit"
    puts "   <message>       - Send chat message"
    puts "\n📝 Start typing messages (they'll be sent on different streams):\n\n"

    while @running
      print "> "

      begin
        input = gets
        break unless input && @running

        handle_input(input.chomp)
        reset_typing_indicator
      rescue Interrupt
        break
      rescue => e
        puts "❌ Input error: #{e.message}"
      end
    end
  end

  def handle_input(input)
    return if input.empty?

    if input.start_with?('/')
      handle_command(input)
    else
      send_chat_message(input)
    end
  end

  def handle_command(command)
    parts = command.split(' ', 2)
    cmd = parts[0].downcase

    case cmd
    when '/help'
      show_help
    when '/join'
      room = parts[1]&.strip
      if room && !room.empty?
        join_room(room)
      else
        puts "❌ Usage: /join <room_name>"
      end
    when '/file'
      filepath = parts[1]&.strip
      if filepath && !filepath.empty?
        send_file(filepath)
      else
        puts "❌ Usage: /file <file_path>"
      end
    when '/status'
      status = parts[1]&.strip || 'online'
      set_presence_status(status)
    when '/quit', '/exit'
      @running = false
    else
      puts "❌ Unknown command: #{cmd}. Type /help for available commands."
    end
  end

  def send_chat_message(message)
    send_message({
      type: 'chat_message',
      message: message
    }, CHAT_STREAM)

    puts "💬 [#{@current_room}] You: #{message}"
  end

  def join_room(room_name)
    @current_room = room_name

    send_message({
      action: 'join_room',
      room: room_name
    }, SYSTEM_STREAM)

    puts "🚪 Joining room: #{room_name}"
  end

  def send_file(filepath)
    filename = File.basename(filepath)

    if File.exist?(filepath)
      size = File.size(filepath)
      puts "📁 Sending file: #{filename} (#{size} bytes)"

      # Send file start notification
      send_message({
        action: 'file_start',
        filename: filename,
        size: size
      }, FILE_STREAM)

      # Simulate file chunks
      chunk_size = 1024
      total_chunks = (size / chunk_size.to_f).ceil

      (1..total_chunks).each do |chunk_num|
        send_message({
          action: 'file_chunk',
          filename: filename,
          chunk_num: chunk_num,
          total_chunks: total_chunks,
          data: "chunk_#{chunk_num}_data"  # Simulated
        }, FILE_STREAM)

        print "📦 Sending chunk #{chunk_num}/#{total_chunks}\r"
        sleep(0.1)  # Simulate transfer time
      end

      # Send completion notification
      send_message({
        action: 'file_complete',
        filename: filename
      }, FILE_STREAM)

      puts "\n✅ File transfer complete: #{filename}"
    else
      puts "❌ File not found: #{filepath}"
    end
  end

  def set_presence_status(status)
    send_message({
      status: status
    }, PRESENCE_STREAM, reliable: false)

    puts "👤 Status set to: #{status}"
  end

  def send_typing_indicator(typing)
    send_message({
      typing: typing
    }, TYPING_STREAM, reliable: false)

    @typing_sent = typing
  end

  def reset_typing_indicator
    if @typing_sent
      send_typing_indicator(false)
    end
  end

  def send_message(data, stream, reliable: true)
    return unless @socket && @running

    begin
      options = {
        message: data.to_json,
        stream: stream
      }

      # For unreliable messages, set unordered flag
      unless reliable
        options[:flags] = SCTP::Socket::SCTP_UNORDERED
      end

      @socket.sendmsg(options)
    rescue => e
      puts "❌ Failed to send message: #{e.message}"
    end
  end

  def message_receiver
    while @running
      begin
        result = @socket.recvmsg(4096)
        next unless result && result[:message]

        data = JSON.parse(result[:message])
        stream = result[:stream] || 0

        handle_received_message(data, stream)

      rescue JSON::ParserError => e
        puts "❌ Invalid message received: #{e.message}"
      rescue => e
        puts "❌ Receive error: #{e.message}"
        break
      end
    end
  rescue => e
    puts "❌ Message receiver error: #{e.message}"
  end

  def handle_received_message(data, stream)
    case stream
    when SYSTEM_STREAM
      handle_system_message(data)
    when CHAT_STREAM
      handle_chat_message(data)
    when FILE_STREAM
      handle_file_message(data)
    when PRESENCE_STREAM
      handle_presence_message(data)
    when TYPING_STREAM
      handle_typing_message(data)
    end
  end

  def handle_system_message(data)
    case data['type']
    when 'welcome'
      puts "\n🎉 #{data['message']}"
      puts "📊 Server streams configuration:"
      data['streams'].each do |stream_id, description|
        puts "   Stream #{stream_id}: #{description}"
      end
      puts
    when 'username_confirmed'
      puts "✅ Username set to: #{data['username']}"
    when 'user_joined'
      if data['old_username']
        puts "🔄 #{data['old_username']} is now known as #{data['username']}"
      else
        puts "👋 #{data['username']} joined the room"
      end
    when 'user_left'
      puts "👋 #{data['username']} left the room"
    when 'room_changed'
      puts "🚪 You joined room: #{data['new_room']}"
    when 'server_shutdown'
      puts "\n📢 #{data['message']}"
      @running = false
    end
  end

  def handle_chat_message(data)
    timestamp = Time.at(data['timestamp']).strftime('%H:%M:%S')
    puts "💬 [#{data['room']}] #{data['username']}: #{data['message']} (#{timestamp})"
  end

  def handle_file_message(data)
    case data['type']
    when 'file_transfer_start'
      puts "📁 #{data['username']} is sending file: #{data['filename']} (#{data['size']} bytes)"
    when 'file_transfer_complete'
      puts "✅ #{data['username']} completed file transfer: #{data['filename']}"
    end
  end

  def handle_presence_message(data)
    puts "👤 #{data['username']} is now: #{data['status']}"
  end

  def handle_typing_message(data)
    if data['typing']
      puts "✏️  #{data['username']} is typing..."
    end
  end

  def presence_updater
    while @running
      sleep(30)  # Send presence every 30 seconds

      if @running
        send_message({
          status: 'online'
        }, PRESENCE_STREAM, reliable: false)
      end
    end
  rescue => e
    puts "❌ Presence updater error: #{e.message}"
  end

  def show_help
    puts "\n💡 Available Commands:"
    puts "   /help           - Show this help"
    puts "   /join <room>    - Join a chat room"
    puts "   /file <path>    - Send a file (simulated)"
    puts "   /status <msg>   - Set presence status"
    puts "   /quit           - Exit"
    puts "   <message>       - Send chat message"
    puts "\n🔀 Stream Information:"
    puts "   Stream 0: System messages (reliable, ordered)"
    puts "   Stream 1: Chat messages (reliable, ordered)"
    puts "   Stream 2: File transfers (reliable, ordered)"
    puts "   Stream 3: Presence updates (unreliable)"
    puts "   Stream 4: Typing indicators (unreliable)"
    puts
  end

  def disconnect
    @running = false

    puts "\n🔌 Disconnecting..."

    # Wait for threads to finish
    [@receiver_thread, @presence_thread].each do |thread|
      thread&.join(1.0) rescue nil
    end

    # Close socket
    @socket&.close rescue nil

    puts "👋 Goodbye!"
  end
end

# Handle graceful shutdown
client = nil
trap('INT') do
  puts "\n🛑 Received interrupt signal"
  client&.disconnect rescue nil
  exit(0)
end

# Start the client
if __FILE__ == $0
  server_addresses = ARGV[0] || ['1.1.1.1', '1.1.1.2']
  client = MultiStreamChatClient.new(server_addresses)
  client.connect
end
