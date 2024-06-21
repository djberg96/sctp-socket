$:.unshift 'lib'
require 'socket'
require 'sctp/socket'

begin
  port = 42000
  socket = SCTP::Socket.new
  #bytes_sent = socket.sendmsg(:message => "Hello World!", :addresses => ['127.0.0.1'], :port => port, :stream => 2)
  socket.connect(:port => port, :addresses => ['127.0.0.1'])
  #bytes_sent = socket.sendv(:messages => ["Hello ", "World!\n", "How ", "are ", "you?"])
  #bytes_sent = socket.sendv(:messages => ["Hello", "World"])
  #bytes_sent = socket.sendv(:messages => ["Hello"])
  #bytes_sent = socket.sendv(:messages => [1, 2, 3])
  #bytes_sent = socket.sendv(["Hello ", "World!\n", "How ", "are ", "you?"])
  #10.times{
  bytes_sent = socket.sendv(["Hello ", "World!\n", "How ", "are ", "you?"])
  #p bytes_sent
  #bytes_sent = socket.sendv(["Hello ", "World!\n", "How ", "are ", "you?"])
  #p bytes_sent
  #bytes_sent = socket.sendv(["Hello ", "World!\n", "How ", "are ", "you?"])
  #p bytes_sent
  #bytes_sent = socket.sendv(:messages => ["Hello ", "World!\n", "How ", "are ", "you?"])
  #bytes_sent = socket.sendv([])
  #}
ensure
  socket.close if socket
end
