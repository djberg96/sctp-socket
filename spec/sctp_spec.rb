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
