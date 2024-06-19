require 'socket'
require 'sctp/socket'

addresses = ['1.1.1.1', '1.1.1.2'] # Adjust as needed

begin
  port = 62324
  socket = SCTP::Socket.new
  socket.port = port

  p socket.sendv(:message => ["Hello ", "World!"], :addresses => addresses)
ensure
  socket.close if socket
end
