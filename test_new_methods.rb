#!/usr/bin/env ruby

require_relative 'lib/sctp/socket'

puts "Testing new SCTP socket methods..."

begin
  # Create a socket
  socket = SCTP::Socket.new

  puts "✓ Socket created successfully"

  # Test if the new methods are defined
  puts "✓ set_default_send_params method exists" if socket.respond_to?(:set_default_send_params)
  puts "✓ set_peer_address_params method exists" if socket.respond_to?(:set_peer_address_params)

  # Test constants
  constants = SCTP::Socket.constants.grep(/SCTP_PR_/)
  puts "✓ Found #{constants.length} PR-SCTP constants: #{constants.join(', ')}" if constants.any?

  socket.close
  puts "✓ Socket closed successfully"

rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first
end

puts "\nAll tests completed!"
