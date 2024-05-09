require 'socket'
require 'sctp/socket'

RSpec.describe SCTP::Socket do
  context "version" do
    example "version is set to the expected value" do
      expect(SCTP::Socket::VERSION).to eq('0.0.5')
    end
  end

  context "constructor" do
    before do
      @socket = nil
    end

    after do
      @socket.close if @socket
    end

    example "constructor with no arguments" do
      expect{ @socket = described_class.new }.not_to raise_error
      expect(@socket.domain).to eq(Socket::AF_INET)
      expect(@socket.type).to eq(Socket::SOCK_SEQPACKET)
    end

    example "constructor with domain argument" do
      expect{ @socket = described_class.new(Socket::AF_INET6) }.not_to raise_error
      expect(@socket.domain).to eq(Socket::AF_INET6)
    end

    example "constructor with type argument" do
      expect{ @socket = described_class.new(Socket::AF_INET, Socket::SOCK_STREAM) }.not_to raise_error
      expect(@socket.type).to eq(Socket::SOCK_STREAM)
    end

    example "constructor only accepts two arguments" do
      expect{ described_class.new(Socket::AF_INET, Socket::SOCK_STREAM, 0) }.to raise_error(ArgumentError)
    end

    example "socket_fd has expected value" do
      @socket = described_class.new
      expect(@socket.sock_fd).to be_a(Integer)
    end

    example "association_id has expected value" do
      @socket = described_class.new
      expect(@socket.association_id).to eq(0)
    end
  end
end
