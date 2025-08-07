require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "constructor" do
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

    example "fileno has expected value" do
      expect(@socket.fileno).to be_a(Integer)
    end

    example "association_id has expected value" do
      expect(@socket.association_id).to eq(0)
    end
  end
end
