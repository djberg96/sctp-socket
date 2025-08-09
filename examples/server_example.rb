require 'sctp/socket'

# SCTP Echo Server Example
puts "SCTP Echo Server - VERSION: #{SCTP::Socket::VERSION}"

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
  socket.bindx(:port => port, :addresses => addresses)
  socket.set_initmsg(:output_streams => 5, :input_streams => 5, :max_attempts => 4)
  socket.subscribe(:data_io => true, :shutdown => true, :send_failure => true, :partial_delivery => true, :association => true)
  socket.listen

  puts "SCTP Echo Server listening on #{addresses.join(', ')}:#{port}"
  puts "Waiting for connections..."

  while true
    info = socket.recvmsg

    # Handle notifications (connections, disconnections, etc.)
    if info.notification
      puts "Notification: #{info.notification.inspect}"
      next
    end

    # Handle data messages
    if info.message && !info.message.empty?
      puts "Received from association #{info.association_id} on stream #{info.stream}: #{info.message.inspect}"

      # Echo the message back to the sender
      echo_message = "Echo: #{info.message}"
      socket.send(:message => echo_message, :association_id => info.association_id)
      puts "Sent echo back: #{echo_message.inspect}"
    end
  end
rescue Interrupt
  puts "\nShutting down echo server..."
ensure
  socket.close if socket
  puts "Echo server stopped."
end
