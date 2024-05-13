require 'socket'
require 'sctp/socket'

# Adjust as needed. Server server_example.rb for creating
# fake network interfaces for testing.
addresses = ['1.1.1.1', '1.1.1.2']

begin
  port = 62324
  socket = SCTP::Socket.new

  # Optional, but could bind to a subset of available addresses
  p socket.bind(:addresses => addresses)

  # Initial connection
  p socket.connect(:addresses => addresses, :port => port)

  3.times{ |n|
    stream = [*0..4].sample # Max 5 streams in server example
    puts "Stream: #{stream}"
    bytes_sent = socket.sendmsg(
      :message   => "#{n+1} Hello World!",
      :addresses => addresses.shuffle,
      :port      => port, # Not sure why I have to specify this again, still working out the kinks
      :stream    => stream,
      :ppid      => 1234567,
      # :flags     => SCTP::Socket::SCTP_UNORDERED | SCTP::Socket::SCTP_SENDALL,
      :ttl       => 100,
    )
    puts "#{n+1}: Bytes sent: #{bytes_sent}"
  }
ensure
  socket.close if socket
end
