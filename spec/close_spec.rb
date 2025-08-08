require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "close" do
    before do
      @csocket = described_class.new
      @cserver = described_class.new
    end

    after do
      @csocket.close if @csocket rescue nil
      @cserver.close if @cserver rescue nil
    end

    example "close basic functionality" do
      expect{ @csocket.close }.not_to raise_error
    end

    example "close argument if present must be a Hash" do
      expect{ @csocket.close(1) }.to raise_error(TypeError)
    end

    example "calling close on a closed socket does not raise error" do
      expect{ 3.times{ @csocket.close } }.not_to raise_error
    end

    example "close accepts a reuse_addr argument" do
      expect{ @csocket.close(reuse_addr: true) }.not_to raise_error
    end

    example "close accepts a linger argument" do
      expect{ @csocket.close(linger: 10) }.not_to raise_error
    end
  end

  context "closed?" do
    before do
      @test_socket = described_class.new
    end

    after do
      @test_socket.close(linger: 0) if @test_socket && !@test_socket.closed? rescue nil
    end

    example "closed? basic functionality" do
      expect(@test_socket).to respond_to(:closed?)
    end

    example "closed? returns false for open socket" do
      expect(@test_socket.closed?).to eq(false)
    end

    example "closed? returns true for closed socket" do
      @test_socket.close
      expect(@test_socket.closed?).to eq(true)
    end

    example "closed? takes no arguments" do
      expect{ @test_socket.closed?(true) }.to raise_error(ArgumentError)
    end

    example "closed? returns boolean value" do
      result = @test_socket.closed?
      expect(result).to be_a(TrueClass).or be_a(FalseClass)
    end

    example "closed? state persists after multiple calls" do
      # Test open state
      expect(@test_socket.closed?).to eq(false)
      expect(@test_socket.closed?).to eq(false)

      # Close and test closed state
      @test_socket.close
      expect(@test_socket.closed?).to eq(true)
      expect(@test_socket.closed?).to eq(true)
    end

    example "closed? works after socket operations" do
      # Perform some socket operations
      expect(@test_socket.closed?).to eq(false)

      # Socket should still be open after getting domain/type
      @test_socket.domain
      @test_socket.type
      expect(@test_socket.closed?).to eq(false)

      # Close and verify
      @test_socket.close
      expect(@test_socket.closed?).to eq(true)
    end

    example "closed? behavior with linger option" do
      expect(@test_socket.closed?).to eq(false)
      @test_socket.close(linger: 0)
      expect(@test_socket.closed?).to eq(true)
    end

    example "closed? behavior with reuse_addr option" do
      expect(@test_socket.closed?).to eq(false)
      @test_socket.close(reuse_addr: true)
      expect(@test_socket.closed?).to eq(true)
    end
  end
end
