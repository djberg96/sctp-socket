#!/usr/bin/env ruby
# Example SCTP server using the SCTP::Server class
# Run with: ruby -I lib examples/sctp_server_example.rb

require 'sctp/socket'

puts "SCTP::Server Example"
puts "==================="

# Example 1: One-to-many server (default mode)
puts "\n1. One-to-many server example:"
puts "   Multiple clients can connect to the same server socket"
puts "   All communication happens through the main server socket"

server = SCTP::Server.new(['127.0.0.1'], 9999)
puts "   Server listening on: #{server}"

# Simulate server operation (normally you'd have a loop here)
puts "   Server ready to receive messages with server.recvmsg"
puts "   Send messages back with server.sendmsg(data, association_id: id)"

server.close
puts "   Server closed"

# Example 2: One-to-one server with peeloff
puts "\n2. One-to-one server example:"
puts "   Each client connection gets its own dedicated socket"
puts "   Uses peeloff() to create individual sockets per association"

server_1to1 = SCTP::Server.new(['127.0.0.1'], 9998, one_to_one: true)
puts "   Server listening on: #{server_1to1}"

# Simulate server operation
puts "   Server ready to accept connections with server.accept"
puts "   Each accepted connection returns a new SCTP::Socket"
puts "   Handle each client in a separate thread"

server_1to1.close
puts "   Server closed"

# Example 3: Server with multiple addresses (multihoming)
puts "\n3. Multihomed server example:"
puts "   SCTP supports binding to multiple IP addresses"

begin
  # This will work if you have multiple addresses configured
  multi_server = SCTP::Server.new(['127.0.0.1', '127.0.0.2'], 9997)
  puts "   Multihomed server: #{multi_server}"
  multi_server.close
rescue => e
  puts "   Multihomed server failed (expected if addresses not configured): #{e.message}"
end

# Example 4: Server with custom options
puts "\n4. Server with custom options:"

custom_server = SCTP::Server.new(['127.0.0.1'], 9996,
  backlog: 64,
  autoclose: 10,
  init_msg: { output_streams: 10, input_streams: 10 }
)
puts "   Custom server: #{custom_server}"
custom_server.close

puts "\nExample complete!"
puts "\nTo test with a real client:"
puts "1. Start the server in one terminal"
puts "2. Use examples/client_example.rb to connect"
puts "3. Or create a simple client with SCTP::Socket.new and connectx()"
