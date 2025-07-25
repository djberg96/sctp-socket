#!/usr/bin/env ruby

require 'sctp/socket'

# Simple SCTP echo server example using SCTP::Server

puts "SCTP Echo Server Example"
puts "========================"

# Create a server that binds to localhost on port 9999
server = SCTP::Server.new(['127.0.0.1'], 9999)

puts "Server listening on #{server.addr.join(', ')}:#{server.local_port}"
puts "Mode: #{server.one_to_one ? 'one-to-one' : 'one-to-many'}"
puts "Press Ctrl+C to stop"

begin
  if server.one_to_one
    # One-to-one mode: accept individual connections
    puts "Waiting for connections..."
    loop do
      client = server.accept
      puts "Accepted connection from association #{client.initial_message[1].association_id}"

      # Handle the connection in a thread
      Thread.new(client) do |c|
        begin
          # Get the initial message that triggered the connection
          data, info = c.initial_message
          puts "Initial message: #{data.inspect}"

          # Echo it back
          c.sendmsg("Echo: #{data}")

          # Continue receiving messages
          loop do
            data, info = c.recvmsg
            puts "Received: #{data.inspect}"
            c.sendmsg("Echo: #{data}")
          end
        rescue => e
          puts "Client connection error: #{e.message}"
        ensure
          c.close
          puts "Client disconnected"
        end
      end
    end
  else
    # One-to-many mode: handle all connections on the same socket
    puts "Waiting for messages..."
    loop do
      data, info = server.recvmsg
      puts "Received from association #{info.association_id}: #{data.inspect}"

      # Echo the message back to the sender
      server.sendmsg("Echo: #{data}", association_id: info.association_id)
    end
  end
rescue Interrupt
  puts "\nShutting down server..."
ensure
  server.close
  puts "Server closed"
end
