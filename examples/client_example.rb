require 'socket'
require 'sctp/socket'

# Adjust as needed. Server server_example.rb for creating
# fake network interfaces for testing.
addresses = ['1.1.1.1', '1.1.1.2']

begin
  port = 62324
  socket = SCTP::Socket.new
  5.times{ |n|
    stream = [*1..5].sample
    puts "Stream: #{stream}"
    bytes_sent = socket.sendmsg(
      :message   => "#{n+1} Hello World!",
      :addresses => addresses.shuffle,
      :port      => port,
      :stream    => stream,
      :ppid      => 1234567,
      #:flags     => SCTP::Socket::SCTP_UNORDERED | SCTP::Socket::SCTP_SENDALL,
      :ttl       => 100,
    )
    puts "Bytes sent: #{bytes_sent}"
  }
ensure
  socket.close if socket
end
