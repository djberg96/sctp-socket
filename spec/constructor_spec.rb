require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "constructor" do
    example "new with default arguments" do
      expect{ described_class.new }.not_to raise_error
    end

    example "new with explicit domain" do
      expect{ described_class.new(Socket::AF_INET) }.not_to raise_error
    end

    example "new with explicit socket type" do
      expect{ described_class.new(Socket::AF_INET, Socket::SOCK_SEQPACKET) }.not_to raise_error
    end

    example "new with third argument raises an error" do
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
