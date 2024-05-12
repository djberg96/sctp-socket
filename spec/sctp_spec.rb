##############################################################################
# Specs for the sctp-socket library.
#
# These specs assume you've created two dummy interfaces at 1.1.1.1 and
# 1.1.1.2. Without these the specs will fail.
##############################################################################
require 'socket'
require 'sctp/socket'

RSpec.describe SCTP::Socket do
  context "version" do
    example "version is set to the expected value" do
      expect(SCTP::Socket::VERSION).to eq('0.0.6')
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

  context "bind" do
    let(:addresses){ %w[1.1.1.1 1.1.1.2] }
    let(:port){ 12345 }

    before do
      @socket = described_class.new
    end

    after do
      @socket.close if @socket
    end

    example "bind both sets and returns port value" do
      port = @socket.bind
      expect(@socket.port).to eq(port)
    end

    example "bind with no arguments" do
      expect{ @socket.bind }.not_to raise_error
    end

    example "bind with addresses" do
      expect{ @socket.bind(:addresses => addresses) }.not_to raise_error
    end

    example "bind with explicit port value" do
      expect{ @socket.bind(:port => port) }.not_to raise_error
      expect(@socket.port).to eq(port)
    end

    example "bind using explicit flags to add addresses" do
      expect{ @socket.bind(:addresses => addresses, :flags => SCTP::Socket::SCTP_BINDX_ADD_ADDR) }.not_to raise_error
    end

    xexample "bind using explicit flags to remove addresses" do
      @socket.bind(:port => port, :addresses => addresses)
      expect{ @socket.bind(:port => port, :addresses => [addresses.first], :flags => SCTP::Socket::SCTP_BINDX_REM_ADDR) }.not_to raise_error
    end
  end
end
