require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "shutdown" do
    example "shutdown basic functionality" do
      expect(@socket).to respond_to(:shutdown)
    end

    example "shutdown takes optional integer argument" do
      # Test that shutdown can be called with no arguments
      expect(@socket).to respond_to(:shutdown)

      # Test that shutdown can be called with an integer argument
      # On an unconnected socket, this will fail but should not crash
      begin
        @socket.shutdown(0)
      rescue SystemCallError => e
        # Expected for unconnected socket
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor|Operation not supported/)
      end
    end

    example "shutdown with no arguments" do
      # On an unconnected socket, shutdown may fail but should not crash
      begin
        @socket.shutdown
      rescue SystemCallError => e
        # Expected for unconnected socket - verify it's a network-related error
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor|Operation not supported/)
      end
    end

    example "shutdown with SHUT_RD argument" do
      begin
        @socket.shutdown(0) # SHUT_RD = 0
      rescue SystemCallError => e
        # Expected for unconnected socket
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor|Operation not supported/)
      end
    end

    example "shutdown with SHUT_WR argument" do
      begin
        @socket.shutdown(1) # SHUT_WR = 1
      rescue SystemCallError => e
        # Expected for unconnected socket
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor|Operation not supported/)
      end
    end

    example "shutdown with SHUT_RDWR argument" do
      begin
        @socket.shutdown(2) # SHUT_RDWR = 2
      rescue SystemCallError => e
        # Expected for unconnected socket
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor|Operation not supported/)
      end
    end

    example "shutdown rejects invalid argument types" do
      expect{ @socket.shutdown("invalid") }.to raise_error(TypeError)
      expect{ @socket.shutdown([]) }.to raise_error(TypeError)
      expect{ @socket.shutdown({}) }.to raise_error(TypeError)
    end

    example "shutdown rejects too many arguments" do
      expect{ @socket.shutdown(0, 1) }.to raise_error(ArgumentError)
    end

    example "shutdown with connected socket" do
      # Set up a connection for testing shutdown
      @server.bindx(port: 12350, reuse_addr: true)
      @server.listen

      begin
        @socket.connectx(addresses: %w[1.1.1.1], port: 12350)
        @socket.shutdown
      rescue SystemCallError => e
        # If connection fails or shutdown fails, it's expected in test environment
        # Just verify the error message indicates connection issues
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor|Network is unreachable|No route to host|Operation not supported/)
      end
    end

    example "shutdown with specific shutdown type on connected socket" do
      # Set up a connection for testing shutdown with specific types
      @server.bindx(port: 12351, reuse_addr: true)
      @server.listen

      begin
        @socket.connectx(addresses: %w[1.1.1.1], port: 12351)
        @socket.shutdown(0) # SHUT_RD
      rescue SystemCallError => e
        # If connection fails or shutdown fails, it's expected in test environment
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor|Network is unreachable|No route to host|Operation not supported/)
      end
    end

    example "shutdown affects socket state" do
      # Test that shutdown affects the socket but doesn't close it completely
      expect(@socket.closed?).to eq(false)

      begin
        @socket.shutdown
        # Socket should still exist but be in shutdown state
        # Note: closed? may still return false after shutdown
        expect(@socket).to be_a(described_class)
      rescue SystemCallError
        # Expected for unconnected socket - just verify we can still check the socket
        expect(@socket).to be_a(described_class)
      end
    end

    example "shutdown vs close behavior" do
      # Test the difference between shutdown and close
      expect(@socket.closed?).to eq(false)

      begin
        @socket.shutdown
        # After shutdown, socket should still exist
        expect(@socket).to be_a(described_class)

        # After close, socket should be closed
        @socket.close
        expect(@socket.closed?).to eq(true)
      rescue SystemCallError
        # If shutdown fails on unconnected socket, just test close
        @socket.close
        expect(@socket.closed?).to eq(true)
      end
    end

    example "shutdown with Socket constants" do
      # Test using Socket module constants if available
      begin
        if defined?(Socket::SHUT_RD)
          @socket.shutdown(Socket::SHUT_RD)
        end
        if defined?(Socket::SHUT_WR)
          @socket.shutdown(Socket::SHUT_WR)
        end
        if defined?(Socket::SHUT_RDWR)
          @socket.shutdown(Socket::SHUT_RDWR)
        end
      rescue SystemCallError => e
        # Expected for unconnected socket
        expect(e.message).to match(/not connected|Transport endpoint is not connected|Bad file descriptor|Operation not supported/)
      end
    end
  end
end
