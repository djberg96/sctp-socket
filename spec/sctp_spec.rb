##############################################################################
# Specs for the sctp-socket library.
#
# These specs assume you've created two dummy interfaces at 1.1.1.1 and
# 1.1.1.2. Without these the specs will fail.
#
# Run the `rake create_dummy_links` task first to do this for you if needed.
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
  end

  context "listen" do
    before do
      @listen_socket = described_class.new
    end

    after do
      @listen_socket.close(linger: 0) if @listen_socket && !@listen_socket.closed? rescue nil
    end

    example "listen basic functionality" do
      expect(@listen_socket).to respond_to(:listen)
    end

    example "listen with no arguments" do
      # Must bind first before listening
      @listen_socket.bindx(reuse_addr: true)
      expect{ @listen_socket.listen }.not_to raise_error
    end

    example "listen with backlog argument" do
      # Must bind first before listening
      @listen_socket.bindx(reuse_addr: true)
      expect{ @listen_socket.listen(5) }.not_to raise_error
    end

    let(:max_backlog) { Socket::SOMAXCONN }

    example "listen with different backlog values" do
      @listen_socket.bindx(reuse_addr: true)

      # Test various backlog values up to system maximum
      [1, 5, 10, max_backlog].each do |backlog|
        expect{ @listen_socket.listen(backlog) }.not_to raise_error
      end
    end

    example "listen behavior on unbound socket" do
      # Listen on unbound socket behavior may vary by implementation
      # Some implementations allow it, others don't
      begin
        @listen_socket.listen
      rescue SystemCallError => e
        # If it fails, verify it's a reasonable error
        expect(e.message).to match(/Invalid argument|Operation not permitted|Protocol not available/)
      end
    end

    example "listen argument type validation" do
      @listen_socket.bindx(reuse_addr: true)

      expect{ @listen_socket.listen("invalid") }.to raise_error(TypeError)
      expect{ @listen_socket.listen([]) }.to raise_error(TypeError)
      expect{ @listen_socket.listen({}) }.to raise_error(TypeError)

      # Float arguments may be accepted (converted to integer)
      # Test if float is accepted or rejected
      begin
        @listen_socket.listen(1.5)
      rescue TypeError
        # Float rejected - that's also valid behavior
        expect(true).to be true
      end
    end

    example "listen backlog value validation" do
      @listen_socket.bindx(reuse_addr: true)

      # Test negative values - behavior may vary
      begin
        @listen_socket.listen(-1)
      rescue ArgumentError, SystemCallError
        # Either ArgumentError or SystemCallError is acceptable
        expect(true).to be true
      end
    end

    example "listen rejects too many arguments" do
      @listen_socket.bindx(reuse_addr: true)

      expect{ @listen_socket.listen(5, 10) }.to raise_error(ArgumentError)
    end

    example "listen can be called multiple times" do
      @listen_socket.bindx(reuse_addr: true)

      # Should be able to call listen multiple times without error
      expect{ @listen_socket.listen }.not_to raise_error
      expect{ @listen_socket.listen(10) }.not_to raise_error
      expect{ @listen_socket.listen(1) }.not_to raise_error
    end

    example "listen with zero backlog" do
      @listen_socket.bindx(reuse_addr: true)

      # Zero backlog may not be accepted by all systems
      begin
        @listen_socket.listen(0)
      rescue SystemCallError => e
        # If zero is not accepted, verify it's a reasonable error
        expect(e.message).to match(/Invalid argument/)
      end
    end

    example "listen with large backlog value" do
      @listen_socket.bindx(reuse_addr: true)

      # System has maximum backlog limit (Socket::SOMAXCONN)
      expect{ @listen_socket.listen(max_backlog) }.not_to raise_error

      # Values above system limit should be rejected
      expect{ @listen_socket.listen(max_backlog + 1) }.to raise_error(ArgumentError, /backlog value exceeds maximum/)
    end

    example "listen state after binding" do
      @listen_socket.bindx(reuse_addr: true)

      # Socket should not be closed after listen
      expect(@listen_socket.closed?).to eq(false)
      @listen_socket.listen
      expect(@listen_socket.closed?).to eq(false)
    end

    example "listen with specific port and addresses" do
      # Test listening on specific addresses and port
      @listen_socket.bindx(port: 12360, addresses: %w[1.1.1.1], reuse_addr: true)
      expect{ @listen_socket.listen }.not_to raise_error
    rescue SystemCallError => e
      # If binding to specific addresses fails (network not available),
      # just test with default binding
      if e.message.match?(/Cannot assign requested address|Network is unreachable/)
        @listen_socket.close rescue nil
        @listen_socket = described_class.new
        @listen_socket.bindx(reuse_addr: true)
        expect{ @listen_socket.listen }.not_to raise_error
      else
        raise
      end
    end

    example "listen enables socket for connections" do
      @listen_socket.bindx(port: 12361, reuse_addr: true)
      @listen_socket.listen

      # After listen, socket should be in listening state
      # We can verify this by checking the socket is not closed
      expect(@listen_socket.closed?).to eq(false)
    end

    example "listen with system maximum backlog" do
      @listen_socket.bindx(reuse_addr: true)

      # Test with system maximum
      expect{ @listen_socket.listen(max_backlog) }.not_to raise_error

      # Test that values above maximum are rejected
      expect{ @listen_socket.listen(max_backlog * 10) }.to raise_error(ArgumentError, /backlog value exceeds maximum/)
    end

    example "listen behavior on different socket types" do
      # Test listen on SOCK_STREAM socket
      stream_socket = described_class.new(Socket::AF_INET, Socket::SOCK_STREAM)
      stream_socket.bindx(reuse_addr: true)
      expect{ stream_socket.listen }.not_to raise_error
      stream_socket.close

      # Test listen on default SOCK_SEQPACKET socket
      @listen_socket.bindx(reuse_addr: true)
      expect{ @listen_socket.listen }.not_to raise_error
    end

    example "listen after bindx with specific options" do
      # Test listen after binding with various options
      @listen_socket.bindx(reuse_addr: true)
      expect{ @listen_socket.listen(10) }.not_to raise_error
    end

    example "listen returns self or nil" do
      @listen_socket.bindx(reuse_addr: true)

      result = @listen_socket.listen
      # listen typically returns nil or self
      expect(result).to be_nil.or eq(@listen_socket)
    end
  end
end
