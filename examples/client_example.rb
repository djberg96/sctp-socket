require 'socket'
require 'sctp/socket'

# Adjust as needed. Server server_example.rb for creating
# fake network interfaces for testing.
addresses = ['1.1.1.1', '1.1.1.2']

begin
  port = 62324
  socket = SCTP::Socket.new
  bytes_sent = socket.sendmsg(:message => "Hello World!", :addresses => addresses, :port => port, :stream => 2)
  p bytes_sent
ensure
  socket.close if socket
end
