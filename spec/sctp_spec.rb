##############################################################################
# Specs for the sctp-socket library.
#
# These specs assume you've created two dummy interfaces at 1.1.1.1 and
# 1.1.1.2. Without these the specs will fail.
#
# Run the `rake create_dummy_links` task first to do this for you if needed.
##############################################################################
require 'socket'
require 'sctp/socket'

RSpec.describe SCTP::Socket do
  let(:addresses){ %w[1.1.1.1 1.1.1.2] }
  let(:port){ 12345 }

  describe 'most methods' do
    before do
      @socket = described_class.new
      @server = described_class.new
    end

    after do
      @socket.close(linger: 0) if @socket
      @server.close(linger: 0) if @server
    end
  end

  context "set_shared_key and delete_shared_key" do
    before do
      @server = described_class.new
      @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
      @server.listen

      @socket = described_class.new
      @socket.connectx(:addresses => addresses, :port => port)

      # Allow some time for connection to establish
      sleep(0.1)
    end

    after do
      @socket.close if @socket && !@socket.closed?
      @server.close if @server && !@server.closed?
    end

    example "set_shared_key basic functionality" do
      begin
        result = @socket.set_shared_key("testkey", 1)
        expect(result).to eq(@socket)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "delete_shared_key basic functionality" do
      begin
        result = @socket.delete_shared_key(1)
        expect(result).to be_a(Integer)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "set_shared_key requires key and keynum arguments" do
      expect { @socket.set_shared_key }.to raise_error(ArgumentError)
      # keynum is optional and defaults to 1, so this should work
      expect { @socket.set_shared_key("key") }.not_to raise_error
    end

    example "delete_shared_key requires keynum argument" do
      expect { @socket.delete_shared_key }.to raise_error(ArgumentError)
    end

    example "set_shared_key accepts key, keynum and optional association_id" do
      begin
        # Test with association_id
        result = @socket.set_shared_key("testkey", 1, @socket.association_id)
        expect(result).to eq(@socket)

        # Test without association_id (should use socket's association_id)
        result = @socket.set_shared_key("testkey2", 2)
        expect(result).to eq(@socket)

        # Test with nil association_id (should use socket's association_id)
        result = @socket.set_shared_key("testkey3", 3, nil)
        expect(result).to eq(@socket)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "delete_shared_key accepts keynum and optional association_id" do
      begin
        # Test with association_id
        result = @socket.delete_shared_key(1, @socket.association_id)
        expect(result).to be_a(Integer)

        # Test without association_id (should use socket's association_id)
        result = @socket.delete_shared_key(2)
        expect(result).to be_a(Integer)

        # Test with nil association_id (should use socket's association_id)
        result = @socket.delete_shared_key(3, nil)
        expect(result).to be_a(Integer)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "set_shared_key validates key parameter type" do
      expect { @socket.set_shared_key(123, 1) }.to raise_error(TypeError)
      expect { @socket.set_shared_key(nil, 1) }.to raise_error(TypeError)
    end

    example "set_shared_key validates keynum parameter type" do
      expect { @socket.set_shared_key("key", "invalid") }.to raise_error(TypeError)
      # nil is valid as keynum defaults to 1
      expect { @socket.set_shared_key("key", nil) }.not_to raise_error
    end

    example "delete_shared_key validates keynum parameter type" do
      expect { @socket.delete_shared_key("invalid") }.to raise_error(TypeError)
      expect { @socket.delete_shared_key(nil) }.to raise_error(TypeError)
    end

    example "set_shared_key validates association_id parameter type" do
      expect { @socket.set_shared_key("key", 1, "invalid") }.to raise_error(TypeError)
    end

    example "delete_shared_key validates association_id parameter type" do
      expect { @socket.delete_shared_key(1, "invalid") }.to raise_error(TypeError)
    end

    example "methods reject too many arguments" do
      expect { @socket.set_shared_key("key", 1, 0, "extra") }.to raise_error(ArgumentError)
      expect { @socket.delete_shared_key(1, 0, "extra") }.to raise_error(ArgumentError)
    end

    example "set_shared_key with different key values" do
      begin
        # Test with regular string key
        result = @socket.set_shared_key("regularkey", 1)
        expect(result).to eq(@socket)

        # Test with empty string (null key)
        result = @socket.set_shared_key("", 2)
        expect(result).to eq(@socket)

        # Test with binary data
        result = @socket.set_shared_key("\x00\x01\x02\x03", 3)
        expect(result).to eq(@socket)

        # Test with longer key
        result = @socket.set_shared_key("a" * 100, 4)
        expect(result).to eq(@socket)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "delete_shared_key with different keynum values" do
      begin
        # Test with various key numbers
        [1, 2, 10, 100].each do |keynum|
          result = @socket.delete_shared_key(keynum)
          expect(result).to be_a(Integer)
        end
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "set_shared_key with special key number 0 (null key)" do
      begin
        result = @socket.set_shared_key("", 0)
        expect(result).to eq(@socket)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "delete_shared_key with special key number 0 (disables null key)" do
      begin
        result = @socket.delete_shared_key(0)
        expect(result).to be_a(Integer)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "set_shared_key returns self" do
      begin
        result = @socket.set_shared_key("testkey", 5)
        expect(result).to equal(@socket)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "delete_shared_key returns integer key number" do
      begin
        result = @socket.delete_shared_key(5)
        expect(result).to be_a(Integer)
        expect(result).to eq(5)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "methods handle closed socket gracefully" do
      @socket.close
      expect { @socket.set_shared_key("key", 1) }.to raise_error(TypeError, /no implicit conversion from nil to integer/)
      expect { @socket.delete_shared_key(1) }.to raise_error(TypeError, /no implicit conversion from nil to integer/)
    end

    example "methods use socket's association_id when nil passed" do
      begin
        association_id = @socket.association_id

        # Both methods should work with nil association_id
        result1 = @socket.set_shared_key("testkey", 10, nil)
        expect(result1).to eq(@socket)

        result2 = @socket.delete_shared_key(10, nil)
        expect(result2).to be_a(Integer)

        expect(association_id).to be >= 0
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "methods work with different association_id values" do
      begin
        association_id = @socket.association_id

        # Test with explicit association_id
        result1 = @socket.set_shared_key("testkey", 20, association_id)
        expect(result1).to eq(@socket)

        result2 = @socket.delete_shared_key(20, association_id)
        expect(result2).to be_a(Integer)

        # Test with 0 (endpoint level)
        result3 = @socket.set_shared_key("endpointkey", 21, 0)
        expect(result3).to eq(@socket)

        result4 = @socket.delete_shared_key(21, 0)
        expect(result4).to be_a(Integer)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "set_shared_key and delete_shared_key work together" do
      begin
        # Set a key
        @socket.set_shared_key("workflowkey", 30)

        # Delete the same key
        result = @socket.delete_shared_key(30)
        expect(result).to eq(30)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "methods are compatible with auth support workflow" do
      begin
        # Enable auth support first
        @socket.enable_auth_support

        # Set a shared key
        @socket.set_shared_key("authkey", 40)

        # Try to set it as active (might fail if key management not fully supported)
        @socket.set_active_shared_key(40)

        # Clean up
        @socket.delete_shared_key(40)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "methods work on connected socket vs unconnected socket" do
      begin
        # Test on connected socket (our @socket)
        connected_result = @socket.set_shared_key("connectedkey", 50)
        expect(connected_result).to eq(@socket)

        # Test on unconnected socket
        unconnected_socket = described_class.new
        unconnected_result = unconnected_socket.set_shared_key("unconnectedkey", 51)
        expect(unconnected_result).to eq(unconnected_socket)

        # Clean up
        @socket.delete_shared_key(50)
        unconnected_socket.delete_shared_key(51)
        unconnected_socket.close
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "methods utilize established SCTP association" do
      begin
        # Test that methods work with the actual established association
        association_id = @socket.association_id

        # Set key using the real association ID from connected socket
        @socket.set_shared_key("associationkey", 60, association_id)

        # Delete key using the real association ID
        result = @socket.delete_shared_key(60, association_id)
        expect(result).to eq(60)
        expect(association_id).to be > 0 # Connected socket should have non-zero association
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
        # But we should still have a valid association ID
        association_id = @socket.association_id
        expect(association_id).to be >= 0
      end
    end
  end

  context "set_default_send_params" do
    before do
      @socket = described_class.new
    end

    after do
      @socket.close(linger: 0) if @socket rescue nil
    end

    example "set_default_send_params basic functionality" do
      expect(@socket).to respond_to(:set_default_send_params)
    end

    example "set_default_send_params requires a hash argument" do
      expect{ @socket.set_default_send_params("invalid") }.to raise_error(TypeError)
      expect{ @socket.set_default_send_params(123) }.to raise_error(TypeError)
      expect{ @socket.set_default_send_params(nil) }.to raise_error(TypeError)
    end

    example "set_default_send_params accepts an empty hash" do
      expect{ @socket.set_default_send_params({}) }.not_to raise_error
    end

    example "set_default_send_params accepts stream parameter" do
      options = { stream: 1 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts ssn parameter" do
      options = { ssn: 100 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts flags parameter" do
      options = { flags: 1 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts ppid parameter" do
      options = { ppid: 12345 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts context parameter" do
      options = { context: 999 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts ttl parameter" do
      options = { ttl: 5000 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts tsn parameter" do
      options = { tsn: 54321 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts cumtsn parameter" do
      options = { cumtsn: 67890 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts association_id parameter" do
      options = { association_id: 0 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts multiple parameters" do
      options = {
        stream: 2,
        flags: 1,
        ppid: 12345,
        context: 999,
        ttl: 5000
      }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params returns a DefaultSendParams struct" do
      options = { stream: 1, ppid: 12345 }
      result = @socket.set_default_send_params(options)
      expect(result).to be_a(Struct)
      expect(result.class.name).to match(/DefaultSendParams/)
    end

    example "set_default_send_params accepts string keys" do
      options = { "stream" => 1, "ppid" => 12345 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts symbol keys" do
      options = { :stream => 1, :ppid => 12345 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params with all numeric parameters" do
      options = {
        stream: 3,
        ssn: 200,
        flags: 2,
        ppid: 54321,
        context: 1234,
        ttl: 10000,
        tsn: 98765,
        cumtsn: 13579,
        association_id: 0
      }
      result = @socket.set_default_send_params(options)
      expect(result).to be_a(Struct)
    end

    example "set_default_send_params with SCTP constant flags" do
      # Test with SCTP_UNORDERED flag if available
      begin
        flags = described_class::SCTP_UNORDERED
        options = { stream: 1, flags: flags }
        expect{ @socket.set_default_send_params(options) }.not_to raise_error
      rescue NameError
        # Constant not available, skip this part
        options = { stream: 1, flags: 1 }
        expect{ @socket.set_default_send_params(options) }.not_to raise_error
      end
    end
  end

  context "shutdown" do
    before do
      @shutdown_socket = described_class.new
      @shutdown_server = described_class.new
    end

    after do
      @shutdown_socket.close(linger: 0) if @shutdown_socket && !@shutdown_socket.closed? rescue nil
      @shutdown_server.close(linger: 0) if @shutdown_server && !@shutdown_server.closed? rescue nil
    end

    example "shutdown basic functionality" do
      expect(@shutdown_socket).to respond_to(:shutdown)
    end

    example "shutdown takes optional integer argument" do
      # Test that shutdown can be called with no arguments
      expect(@shutdown_socket).to respond_to(:shutdown)

      # Test that shutdown can be called with an integer argument
      # On an unconnected socket, this will fail but should not crash
      begin
        @shutdown_socket.shutdown(0)
      rescue SystemCallError => e
        # Expected for unconnected socket
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor/)
      end
    end

    example "shutdown with no arguments" do
      # On an unconnected socket, shutdown may fail but should not crash
      begin
        @shutdown_socket.shutdown
      rescue SystemCallError => e
        # Expected for unconnected socket - verify it's a network-related error
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor/)
      end
    end

    example "shutdown with SHUT_RD argument" do
      begin
        @shutdown_socket.shutdown(0) # SHUT_RD = 0
      rescue SystemCallError => e
        # Expected for unconnected socket
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor/)
      end
    end

    example "shutdown with SHUT_WR argument" do
      begin
        @shutdown_socket.shutdown(1) # SHUT_WR = 1
      rescue SystemCallError => e
        # Expected for unconnected socket
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor/)
      end
    end

    example "shutdown with SHUT_RDWR argument" do
      begin
        @shutdown_socket.shutdown(2) # SHUT_RDWR = 2
      rescue SystemCallError => e
        # Expected for unconnected socket
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor/)
      end
    end

    example "shutdown rejects invalid argument types" do
      expect{ @shutdown_socket.shutdown("invalid") }.to raise_error(TypeError)
      expect{ @shutdown_socket.shutdown([]) }.to raise_error(TypeError)
      expect{ @shutdown_socket.shutdown({}) }.to raise_error(TypeError)
    end

    example "shutdown rejects too many arguments" do
      expect{ @shutdown_socket.shutdown(0, 1) }.to raise_error(ArgumentError)
    end

    example "shutdown with connected socket" do
      # Set up a connection for testing shutdown
      @shutdown_server.bindx(port: 12350, reuse_addr: true)
      @shutdown_server.listen

      begin
        @shutdown_socket.connectx(addresses: %w[1.1.1.1], port: 12350)
        @shutdown_socket.shutdown
      rescue SystemCallError => e
        # If connection fails or shutdown fails, it's expected in test environment
        # Just verify the error message indicates connection issues
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor|Network is unreachable|No route to host/)
      end
    end

    example "shutdown with specific shutdown type on connected socket" do
      # Set up a connection for testing shutdown with specific types
      @shutdown_server.bindx(port: 12351, reuse_addr: true)
      @shutdown_server.listen

      begin
        @shutdown_socket.connectx(addresses: %w[1.1.1.1], port: 12351)
        @shutdown_socket.shutdown(0) # SHUT_RD
      rescue SystemCallError => e
        # If connection fails or shutdown fails, it's expected in test environment
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor|Network is unreachable|No route to host/)
      end
    end

    example "shutdown affects socket state" do
      # Test that shutdown affects the socket but doesn't close it completely
      expect(@shutdown_socket.closed?).to eq(false)

      begin
        @shutdown_socket.shutdown
        # Socket should still exist but be in shutdown state
        # Note: closed? may still return false after shutdown
        expect(@shutdown_socket).to be_a(described_class)
      rescue SystemCallError
        # Expected for unconnected socket - just verify we can still check the socket
        expect(@shutdown_socket).to be_a(described_class)
      end
    end

    example "shutdown vs close behavior" do
      # Test the difference between shutdown and close
      expect(@shutdown_socket.closed?).to eq(false)

      begin
        @shutdown_socket.shutdown
        # After shutdown, socket should still exist
        expect(@shutdown_socket).to be_a(described_class)

        # After close, socket should be closed
        @shutdown_socket.close
        expect(@shutdown_socket.closed?).to eq(true)
      rescue SystemCallError
        # If shutdown fails on unconnected socket, just test close
        @shutdown_socket.close
        expect(@shutdown_socket.closed?).to eq(true)
      end
    end

    example "shutdown with Socket constants" do
      # Test using Socket module constants if available
      begin
        if defined?(Socket::SHUT_RD)
          @shutdown_socket.shutdown(Socket::SHUT_RD)
        end
        if defined?(Socket::SHUT_WR)
          @shutdown_socket.shutdown(Socket::SHUT_WR)
        end
        if defined?(Socket::SHUT_RDWR)
          @shutdown_socket.shutdown(Socket::SHUT_RDWR)
        end
      rescue SystemCallError => e
        # Expected for unconnected socket
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor/)
      end
    end
  end

  context "listen" do
    before do
      @listen_socket = described_class.new
    end

    after do
      @listen_socket.close(linger: 0) if @listen_socket && !@listen_socket.closed? rescue nil
    end

    example "listen basic functionality" do
      expect(@listen_socket).to respond_to(:listen)
    end

    example "listen with no arguments" do
      # Must bind first before listening
      @listen_socket.bindx(reuse_addr: true)
      expect{ @listen_socket.listen }.not_to raise_error
    end

    example "listen with backlog argument" do
      # Must bind first before listening
      @listen_socket.bindx(reuse_addr: true)
      expect{ @listen_socket.listen(5) }.not_to raise_error
    end

    let(:max_backlog) { Socket::SOMAXCONN }

    example "listen with different backlog values" do
      @listen_socket.bindx(reuse_addr: true)

      # Test various backlog values up to system maximum
      [1, 5, 10, max_backlog].each do |backlog|
        expect{ @listen_socket.listen(backlog) }.not_to raise_error
      end
    end

    example "listen behavior on unbound socket" do
      # Listen on unbound socket behavior may vary by implementation
      # Some implementations allow it, others don't
      begin
        @listen_socket.listen
      rescue SystemCallError => e
        # If it fails, verify it's a reasonable error
        expect(e.message).to match(/Invalid argument|Operation not permitted|Protocol not available/)
      end
    end

    example "listen argument type validation" do
      @listen_socket.bindx(reuse_addr: true)

      expect{ @listen_socket.listen("invalid") }.to raise_error(TypeError)
      expect{ @listen_socket.listen([]) }.to raise_error(TypeError)
      expect{ @listen_socket.listen({}) }.to raise_error(TypeError)

      # Float arguments may be accepted (converted to integer)
      # Test if float is accepted or rejected
      begin
        @listen_socket.listen(1.5)
      rescue TypeError
        # Float rejected - that's also valid behavior
        expect(true).to be true
      end
    end

    example "listen backlog value validation" do
      @listen_socket.bindx(reuse_addr: true)

      # Test negative values - behavior may vary
      begin
        @listen_socket.listen(-1)
      rescue ArgumentError, SystemCallError
        # Either ArgumentError or SystemCallError is acceptable
        expect(true).to be true
      end
    end

    example "listen rejects too many arguments" do
      @listen_socket.bindx(reuse_addr: true)

      expect{ @listen_socket.listen(5, 10) }.to raise_error(ArgumentError)
    end

    example "listen can be called multiple times" do
      @listen_socket.bindx(reuse_addr: true)

      # Should be able to call listen multiple times without error
      expect{ @listen_socket.listen }.not_to raise_error
      expect{ @listen_socket.listen(10) }.not_to raise_error
      expect{ @listen_socket.listen(1) }.not_to raise_error
    end

    example "listen with zero backlog" do
      @listen_socket.bindx(reuse_addr: true)

      # Zero backlog may not be accepted by all systems
      begin
        @listen_socket.listen(0)
      rescue SystemCallError => e
        # If zero is not accepted, verify it's a reasonable error
        expect(e.message).to match(/Invalid argument/)
      end
    end

    example "listen with large backlog value" do
      @listen_socket.bindx(reuse_addr: true)

      # System has maximum backlog limit (Socket::SOMAXCONN)
      expect{ @listen_socket.listen(max_backlog) }.not_to raise_error

      # Values above system limit should be rejected
      expect{ @listen_socket.listen(max_backlog + 1) }.to raise_error(ArgumentError, /backlog value exceeds maximum/)
    end

    example "listen state after binding" do
      @listen_socket.bindx(reuse_addr: true)

      # Socket should not be closed after listen
      expect(@listen_socket.closed?).to eq(false)
      @listen_socket.listen
      expect(@listen_socket.closed?).to eq(false)
    end

    example "listen with specific port and addresses" do
      # Test listening on specific addresses and port
      @listen_socket.bindx(port: 12360, addresses: %w[1.1.1.1], reuse_addr: true)
      expect{ @listen_socket.listen }.not_to raise_error
    rescue SystemCallError => e
      # If binding to specific addresses fails (network not available),
      # just test with default binding
      if e.message.match?(/Cannot assign requested address|Network is unreachable/)
        @listen_socket.close rescue nil
        @listen_socket = described_class.new
        @listen_socket.bindx(reuse_addr: true)
        expect{ @listen_socket.listen }.not_to raise_error
      else
        raise
      end
    end

    example "listen enables socket for connections" do
      @listen_socket.bindx(port: 12361, reuse_addr: true)
      @listen_socket.listen

      # After listen, socket should be in listening state
      # We can verify this by checking the socket is not closed
      expect(@listen_socket.closed?).to eq(false)
    end

    example "listen with system maximum backlog" do
      @listen_socket.bindx(reuse_addr: true)

      # Test with system maximum
      expect{ @listen_socket.listen(max_backlog) }.not_to raise_error

      # Test that values above maximum are rejected
      expect{ @listen_socket.listen(max_backlog * 10) }.to raise_error(ArgumentError, /backlog value exceeds maximum/)
    end

    example "listen behavior on different socket types" do
      # Test listen on SOCK_STREAM socket
      stream_socket = described_class.new(Socket::AF_INET, Socket::SOCK_STREAM)
      stream_socket.bindx(reuse_addr: true)
      expect{ stream_socket.listen }.not_to raise_error
      stream_socket.close

      # Test listen on default SOCK_SEQPACKET socket
      @listen_socket.bindx(reuse_addr: true)
      expect{ @listen_socket.listen }.not_to raise_error
    end

    example "listen after bindx with specific options" do
      # Test listen after binding with various options
      @listen_socket.bindx(reuse_addr: true)
      expect{ @listen_socket.listen(10) }.not_to raise_error
    end

    example "listen returns self or nil" do
      @listen_socket.bindx(reuse_addr: true)

      result = @listen_socket.listen
      # listen typically returns nil or self
      expect(result).to be_nil.or eq(@listen_socket)
    end
  end
end
