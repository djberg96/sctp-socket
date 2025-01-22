##############################################################################
# Specs for the sctp-socket library.
#
# These specs assume you've created two dummy interfaces at 1.1.1.1 and
# 1.1.1.2. Without these the specs will fail.
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

    context "version" do
      example "version is set to the expected value" do
        expect(SCTP::Socket::VERSION).to eq('0.1.3')
      end
    end

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

    # For the purposes of these specs we're setting reuse_addr to true just
    # to avoid address-in-use errors, as we don't care about data loss.
    #
    context "bindx" do
      example "bindx both sets and returns port value" do
        port = @server.bindx(:reuse_addr => true)
        expect(@server.port).to eq(port)
      end

      example "bindx with no arguments" do
        expect{ @server.bindx(:reuse_addr => true) }.not_to raise_error
      end

      example "bindx with addresses" do
        expect{ @server.bindx(:addresses => addresses, :reuse_addr => true) }.not_to raise_error
      end

      example "bindx with explicit port value" do
        expect{ @server.bindx(:port => port, :reuse_addr => true) }.not_to raise_error
        expect(@server.port).to eq(port)
      end

      example "bindx using explicit flags to add addresses" do
        expect{
          @server.bindx(
            :addresses => addresses,
            :flags => SCTP::Socket::SCTP_BINDX_ADD_ADDR,
            :reuse_addr => true
          )
        }.not_to raise_error
      end

      example "bindx using explicit flags to remove addresses" do
        @server.bindx(:port => port, :addresses => addresses)
        expect{
          @server.bindx(
            :port => port,
            :addresses => [addresses.last],
            :flags => SCTP::Socket::SCTP_BINDX_REM_ADDR,
            :reuse_addr => true
          )
        }.not_to raise_error
      end
    end

    context "connectx" do
      before do
        @server.bindx(:port => port, :reuse_addr => true)
        @server.listen
      end

      example "connectx basic check" do
        expect{ @socket.connectx(:addresses => addresses, :port => port) }.not_to raise_error
      end

      example "association ID is set after connectx" do
        @socket.connectx(:addresses => addresses, :port => port)
        expect(@socket.association_id).to be > 0
      end

      example "connectx requires both a port and an array of addresses" do
        expect{ @socket.connectx }.to raise_error(ArgumentError)
        expect{ @socket.connectx(:port => port) }.to raise_error(ArgumentError)
        expect{ @socket.connectx(:addresses => addresses) }.to raise_error(ArgumentError)
      end
    end

    context "getpeernames" do
      before do
        @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
        @server.listen
      end

      example "getpeernames returns the expected array" do
        @socket.connectx(:addresses => addresses, :port => port)
        expect(@socket.getpeernames).to eq(addresses)
      end
    end

    context "getlocalnames" do
      before do
        @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
        @server.listen
      end

      # TODO: FreeBSD is picking up localhost and em0 here, is that normal?
      example "getlocalnames returns the expected array" do
        @socket.connectx(:addresses => addresses, :port => port)
        expect(@socket.getlocalnames).to include(*addresses)
      end
    end

    context "get_status" do
      before do
        @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
        @server.listen
        @socket.connectx(:addresses => addresses, :port => port, :reuse_addr => true)
      end

      example "get_status return the expected struct" do
        expect(@socket.get_status).to be_a(Struct::Status)
      end

      example "status struct contains expected values" do
        struct = @socket.get_status
        expect(struct.association_id).to be_a(Integer)
        expect(struct.state).to be_a(Integer)
        expect(struct.receive_window).to be_a(Integer)
        expect(struct.unacknowledged_data).to be_a(Integer)
        expect(struct.pending_data).to be_a(Integer)
        expect(struct.inbound_streams).to be_a(Integer)
        expect(struct.outbound_streams).to be_a(Integer)
        expect(struct.fragmentation_point).to be_a(Integer)
        expect(struct.primary).to eq(addresses.first)
      end
    end

    context "subscribe" do
      let(:addresses){ %w[1.1.1.1 1.1.1.2] }
      let(:port){ 12345 }

      before do
        @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
        @server.listen
      end

      example "subscribe accepts a hash of options" do
        expect{ @server.subscribe(:data_io => true) }.not_to raise_error
        expect{ @server.subscribe(1) }.to raise_error(TypeError)
      end
    end

    context "get_subscriptions" do
      let(:addresses){ %w[1.1.1.1 1.1.1.2] }
      let(:port){ 12345 }
      let(:subscriptions){ {:data_io => true, :shutdown => true} }

      before do
        @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
        @server.subscribe(subscriptions)
      end

      example "get_subscriptions returns expected values" do
        subscriptions = @server.get_subscriptions
        expect(subscriptions[:data_io]).to be true
        expect(subscriptions[:shutdown]).to be true
        expect(subscriptions[:association]).to be false
        expect(subscriptions[:authentication]).to be false
      end

      example "get_subscriptions does not accept any arguments" do
        expect{ @server.get_subscriptions(true) }.to raise_error(ArgumentError)
      end
    end
  end

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

    example "calling close on a closed socket raises an error" do
      expect{ 2.times{ @csocket.close } }.to raise_error(SystemCallError)
    end

    example "close accepts a reuse_addr argument" do
      expect{ @csocket.close(reuse_addr: true) }.not_to raise_error
    end

    example "close accepts a linger argument" do
      expect{ @csocket.close(linger: 10) }.not_to raise_error
    end
  end
end
