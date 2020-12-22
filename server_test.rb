$:.unshift 'lib'
require 'sctp/socket'

port = 42000
addresses = ['127.0.0.1']

begin
  socket = SCTPSocket.new
  socket.bindx(port: port, addresses: addresses)
  socket.listen

  while true
    data = socket.recvmsg
    p data
  end
ensure
  socket.close if socket
end
