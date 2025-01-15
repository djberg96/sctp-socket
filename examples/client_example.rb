require 'socket'
require 'sctp/socket'

# Adjust as needed. Server server_example.rb for creating
# fake network interfaces for testing.
addresses = ['1.1.1.1', '1.1.1.2']

begin
  port = 62324
  socket = SCTP::Socket.new

  # Optional, but could bind to a subset of available addresses
  # p socket.bindx(:addresses => addresses)

  # Initial connection
  p socket.connectx(:addresses => addresses, :port => port)
  p socket.get_status

  # Try a sendv
  p socket.sendv(:message => ["Hello ", "World!"])

  # Send messages on separate streams of the same connection
  arr = []

  0.upto(4) do |n|
    arr << Thread.new do |t|
      puts "Stream: #{n}"
      bytes_sent = socket.sendmsg(
        :message   => "Hello World: #{n+1}",
        :addresses => addresses.shuffle,
        :stream    => n,
        :port      => port
      )
      puts "Bytes Sent: #{bytes_sent}"
    end
  end

  arr.map(&:join)
ensure
  socket.close if socket
end
