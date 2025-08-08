require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "close" do
    example "close basic functionality" do
      expect{ @socket.close }.not_to raise_error
    end

    example "close argument if present must be a Hash" do
      expect{ @socket.close(1) }.to raise_error(TypeError)
    end

    example "calling close on a closed socket does not raise error" do
      expect{ 3.times{ @socket.close } }.not_to raise_error
    end

    example "close accepts a reuse_addr argument" do
      expect{ @socket.close(reuse_addr: true) }.not_to raise_error
    end

    example "close accepts a linger argument" do
      expect{ @socket.close(linger: 10) }.not_to raise_error
    end
  end

  context "closed?" do
    example "closed? basic functionality" do
      expect(@socket).to respond_to(:closed?)
    end

    example "closed? returns false for open socket" do
      expect(@socket.closed?).to eq(false)
    end

    example "closed? returns true for closed socket" do
      @socket.close
      expect(@socket.closed?).to eq(true)
    end

    example "closed? takes no arguments" do
      expect{ @socket.closed?(true) }.to raise_error(ArgumentError)
    end

    example "closed? returns boolean value" do
      result = @socket.closed?
      expect(result).to be_a(TrueClass).or be_a(FalseClass)
    end

    example "closed? state persists after multiple calls" do
      # Test open state
      expect(@socket.closed?).to eq(false)
      expect(@socket.closed?).to eq(false)

      # Close and test closed state
      @socket.close
      expect(@socket.closed?).to eq(true)
      expect(@socket.closed?).to eq(true)
    end

    example "closed? works after socket operations" do
      # Perform some socket operations
      expect(@socket.closed?).to eq(false)

      # Socket should still be open after getting domain/type
      @socket.domain
      @socket.type
      expect(@socket.closed?).to eq(false)

      # Close and verify
      @socket.close
      expect(@socket.closed?).to eq(true)
    end

    example "closed? behavior with linger option" do
      expect(@socket.closed?).to eq(false)
      @socket.close(linger: 0)
      expect(@socket.closed?).to eq(true)
    end

    example "closed? behavior with reuse_addr option" do
      expect(@socket.closed?).to eq(false)
      @socket.close(reuse_addr: true)
      expect(@socket.closed?).to eq(true)
    end
  end
end
