require 'socket'
require 'sctp/socket'

# SCTP Echo Client Example
puts "SCTP Echo Client - Testing echo server"

# Adjust as needed. See server_example.rb for creating
# fake network interfaces for testing.
addresses = ['1.1.1.1', '1.1.1.2']

begin
  port = 62324
  socket = SCTP::Socket.new

  # Configure SCTP parameters to match server
  socket.set_initmsg(:output_streams => 5, :input_streams => 5, :max_attempts => 4)
  socket.subscribe(:data_io => true, :shutdown => true, :send_failure => true, :partial_delivery => true)

  # Optional, but could bind to a subset of available addresses
  p socket.bindx(:addresses => addresses)

  # Initial connection
  puts "Connecting to echo server at #{addresses.join(', ')}:#{port}"
  socket.connectx(:addresses => addresses, :port => port)
  puts "Connected successfully!"
  puts "Status: #{socket.get_status}"

  # Test messages to send to the echo server
  test_messages = [
    "Hello, SCTP Echo Server!",
    "How are you doing?",
    "Testing multiple streams",
    "This is stream 3",
    "Final test message"
  ]

  # Send messages on different streams and wait for echoes
  test_messages.each_with_index do |message, stream|
    puts "\n--- Testing Stream #{stream} ---"
    puts "Sending: #{message.inspect}"

    # Send message on this stream
    bytes_sent = socket.send(
      :message => message,
      :stream  => stream
    )
    puts "Bytes sent: #{bytes_sent}"

    # Receive the echo
    response = socket.recvmsg
    puts "Received echo: #{response.message.inspect} on stream #{response.stream}"

    # Verify it's an echo
    if response.message == "Echo: #{message}"
      puts "✓ Echo verification successful!"
    else
      puts "✗ Echo verification failed!"
    end

    sleep 0.5  # Small delay between messages
  end

  puts "\n--- All echo tests completed! ---"

rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace
ensure
  socket.close if socket
  puts "Client disconnected."
end
