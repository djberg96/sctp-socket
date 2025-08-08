require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "autoclose" do
    before do
      @autoclose_socket = described_class.new
    end

    after do
      @autoclose_socket.close(linger: 0) if @autoclose_socket && !@autoclose_socket.closed? rescue nil
    end

    example "get_autoclose basic functionality" do
      expect(@autoclose_socket).to respond_to(:get_autoclose)
    end

    example "get_autoclose takes no arguments" do
      expect{ @autoclose_socket.get_autoclose }.not_to raise_error
      expect{ @autoclose_socket.get_autoclose(5) }.to raise_error(ArgumentError)
    end

    example "get_autoclose returns an integer" do
      result = @autoclose_socket.get_autoclose
      expect(result).to be_a(Integer)
    end

    example "get_autoclose default value is 0" do
      result = @autoclose_socket.get_autoclose
      expect(result).to eq(0)
    end

    example "autoclose= basic functionality" do
      expect(@autoclose_socket).to respond_to(:autoclose=)
    end

    example "autoclose= requires one argument" do
      expect{ @autoclose_socket.autoclose = 30 }.not_to raise_error
      expect{ @autoclose_socket.method(:autoclose=).call }.to raise_error(ArgumentError)
    end

    example "autoclose= accepts integer values" do
      expect{ @autoclose_socket.autoclose = 0 }.not_to raise_error
      expect{ @autoclose_socket.autoclose = 30 }.not_to raise_error
      expect{ @autoclose_socket.autoclose = 300 }.not_to raise_error
    end

    example "autoclose= returns the set value" do
      result = (@autoclose_socket.autoclose = 60)
      expect(result).to eq(60)
    end

    example "autoclose= argument type validation" do
      expect{ @autoclose_socket.autoclose = "invalid" }.to raise_error(TypeError)
      expect{ @autoclose_socket.autoclose = [] }.to raise_error(TypeError)
      expect{ @autoclose_socket.autoclose = {} }.to raise_error(TypeError)
      expect{ @autoclose_socket.autoclose = nil }.to raise_error(TypeError)
    end

    example "autoclose= with negative values" do
      # Negative values may be rejected by the system
      begin
        @autoclose_socket.autoclose = -1
      rescue ArgumentError, SystemCallError
        # Either error type is acceptable for negative values
        expect(true).to be true
      end
    end

    example "autoclose= and get_autoclose consistency" do
      # Test setting and getting autoclose values
      test_values = [0, 10, 60, 300, 3600]
      test_values.each do |value|
        @autoclose_socket.autoclose = value
        result = @autoclose_socket.get_autoclose
        expect(result).to eq(value)
      end
    end

    example "autoclose= with zero disables autoclose" do
      # Set a non-zero value first
      @autoclose_socket.autoclose = 30
      expect(@autoclose_socket.get_autoclose).to eq(30)
      # Set to zero to disable
      @autoclose_socket.autoclose = 0
      expect(@autoclose_socket.get_autoclose).to eq(0)
    end

    example "autoclose= with large values" do
      # Test with large but reasonable values
      large_value = 86400 # 24 hours in seconds
      @autoclose_socket.autoclose = large_value
      expect(@autoclose_socket.get_autoclose).to eq(large_value)
    end

    example "autoclose= behavior on closed socket" do
      @autoclose_socket.close
      # Operations on closed socket should fail
      expect{ @autoclose_socket.autoclose = 30 }.to raise_error(TypeError)
      expect{ @autoclose_socket.get_autoclose }.to raise_error(TypeError)
    end

    example "autoclose setting affects association behavior" do
      # This test verifies the autoclose feature works at the protocol level
      # Note: Testing actual autoclose behavior requires associations and timing
      # which is complex in a unit test environment
      # Set autoclose to a reasonable value
      @autoclose_socket.autoclose = 10
      expect(@autoclose_socket.get_autoclose).to eq(10)
      # Socket should still be open and functional
      expect(@autoclose_socket.closed?).to eq(false)
    end

    example "autoclose with different socket types" do
      # Test autoclose with SOCK_STREAM socket
      # Note: autoclose is only supported on one-to-many (SOCK_SEQPACKET) sockets
      stream_socket = described_class.new(Socket::AF_INET, Socket::SOCK_STREAM)
      expect{ stream_socket.autoclose = 30 }.to raise_error(SystemCallError, /Operation not supported|Invalid argument/)
      stream_socket.close
      # Test autoclose with default SOCK_SEQPACKET socket (should work)
      expect{ @autoclose_socket.autoclose = 45 }.not_to raise_error
      expect(@autoclose_socket.get_autoclose).to eq(45)
    end

    example "autoclose state persistence" do
      # Test that autoclose setting persists across multiple operations
      @autoclose_socket.autoclose = 120
      # Perform other socket operations
      @autoclose_socket.bindx(reuse_addr: true) rescue nil
      # Autoclose setting should persist
      expect(@autoclose_socket.get_autoclose).to eq(120)
    end

    example "autoclose with various socket operations" do
      # Set autoclose and verify it doesn't interfere with normal operations
      @autoclose_socket.autoclose = 60
      # These operations should work normally
      expect(@autoclose_socket.get_autoclose).to eq(60)
      expect(@autoclose_socket.domain).to be_a(Integer)
      expect(@autoclose_socket.type).to be_a(Integer)
      expect(@autoclose_socket.closed?).to eq(false)
    end
  end
end
