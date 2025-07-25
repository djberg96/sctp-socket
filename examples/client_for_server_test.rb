#!/usr/bin/env ruby

require 'sctp/socket'

# Simple SCTP client to test with the server

puts "SCTP Client Example"
puts "==================="

begin
  # Connect to the server
  client = SCTP::Socket.new
  client.connectx(addresses: ['127.0.0.1'], port: 9999)

  puts "Connected to server at 127.0.0.1:9999"

  # Send a few test messages
  ["Hello, SCTP!", "How are you?", "Goodbye!"].each_with_index do |message, i|
    puts "Sending: #{message}"
    client.sendmsg(message: message, stream: i % 3)  # Use different streams

    # Receive the echo
    data, info = client.recvmsg
    puts "Received: #{data.inspect} on stream #{info.stream}"

    sleep 1
  end

rescue => e
  puts "Error: #{e.message}"
ensure
  client.close if client
  puts "Client closed"
end
