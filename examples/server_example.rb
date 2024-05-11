require 'sctp/socket'

# To test multiple IP addresses locally:
#
# sudo apt install iproute2
# Add 'dummy' to /etc/modules
#
# sudo ip link add dummy1 type dummy
# sudo ip link add dummy2 type dummy
#
# sudo ip addr add 1.1.1.1/24 dev dummy1
# sudo ip addr add 1.1.1.2/24 dev dummy2
#
# sudo ip link set dummy1 up
# sudo ip link set dummy2 up

# Adjust IP addresses as needed
addresses = ['1.1.1.1', '1.1.1.2']

begin
  port = 62324
  socket = SCTP::Socket.new
  socket.bind(:port => port, :addresses => addresses)
  socket.set_initmsg(:output_streams => 5, :input_streams => 5, :max_attempts => 4)
  socket.listen

  while true
    info = socket.recvmsg
    p info
  end
ensure
  socket.close
end
