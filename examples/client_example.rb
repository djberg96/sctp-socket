require 'socket'
require 'sctp/socket'

begin
  port = 62324
  socket = SCTP::Socket.new
  bytes_sent = socket.sendmsg(:message => "Hello World!", :addresses => ['127.0.0.1'], :port => port, :stream => 2)
  p bytes_sent
ensure
  socket.close if socket
end
