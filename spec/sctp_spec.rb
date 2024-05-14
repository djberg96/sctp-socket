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

  context "connect" do
    let(:addresses){ %w[1.1.1.1 1.1.1.2] }
    let(:port){ 12345 }

    before do
      @socket = described_class.new
      @socket.bind(:port => port)
    end

    after do
      @socket.close if @socket
    end

    example "connect basic check" do
      expect{ @socket.connect(:addresses => addresses, :port => port) }.not_to raise_error
    end

    example "association ID is set after connect" do
      @socket.connect(:addresses => addresses, :port => port)
      expect(@socket.association_id).to be > 0
    end

    example "connect requires both a port and an array of addresses" do
      expect{ @socket.connect }.to raise_error(ArgumentError)
      expect{ @socket.connect(:port => port) }.to raise_error(ArgumentError)
      expect{ @socket.connect(:addresses => addresses) }.to raise_error(ArgumentError)
    end
  end

  context "close" do
    before do
      @socket = described_class.new
    end

    example "close basic functionality" do
      expect{ @socket.close }.not_to raise_error
    end

    example "close does not take any arguments" do
      expect{ @socket.close(1) }.to raise_error(ArgumentError)
    end

    example "calling close on a closed socket raises an error" do
      expect{ 2.times{ @socket.close } }.to raise_error(SystemCallError)
    end
  end

  context "getpeernames" do
    let(:addresses){ %w[1.1.1.1 1.1.1.2] }
    let(:port){ 12345 }

    before do
      @server = described_class.new
      @socket = described_class.new
      @server.bind(:addresses => addresses, :port => port)
      @server.listen
    end

    after do
      @socket.close if @socket
      @server.close if @server
    end

    example "getpeernames returns the expected array" do
      @socket.connect(:addresses => addresses, :port => port)
      expect(@socket.getpeernames).to eq(addresses)
    end

    example "getpeernames does not accept arguments" do
      expect{ @socket.getpeernames(true) }.to raise_error(ArgumentError)
    end
  end

  context "getlocalnames" do
    let(:addresses){ %w[1.1.1.1 1.1.1.2] }
    let(:port){ 12345 }

    before do
      @server = described_class.new
      @socket = described_class.new
      @server.bind(:addresses => addresses, :port => port)
      @server.listen
    end

    after do
      @socket.close if @socket
      @server.close if @server
    end

    example "getlocalnames returns the expected array" do
      @socket.connect(:addresses => addresses, :port => port)
      expect(@socket.getlocalnames).to eq(addresses)
    end

    example "getlocalnames does not accept arguments" do
      expect{ @socket.getlocalnames(true) }.to raise_error(ArgumentError)
    end
  end
end
