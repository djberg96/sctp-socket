require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "recvmsg" do
    before do
      @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
      @server.set_initmsg(:output_streams => 5, :input_streams => 5, :max_attempts => 4)
      @server.subscribe(:data_io => true, :shutdown => true, :association => true)
      @server.listen

      @socket.connectx(:addresses => addresses, :port => port)

      # Allow some time for connection to establish
      sleep(0.1)
    end

    after do
      @socket.close if @socket && !@socket.closed?
      @server.close if @server && !@server.closed?
    end

    example "recvmsg basic functionality" do
      expect(@socket).to respond_to(:recvmsg)
    end

    example "recvmsg validates flags parameter type" do
      expect { @socket.recvmsg("not an integer") }.to raise_error(TypeError)
      expect { @socket.recvmsg([]) }.to raise_error(TypeError)
      expect { @socket.recvmsg({}) }.to raise_error(TypeError)
    end

    example "recvmsg validates buffer_size parameter type" do
      expect { @socket.recvmsg(0, "not an integer") }.to raise_error(TypeError)
      expect { @socket.recvmsg(0, []) }.to raise_error(TypeError)
      expect { @socket.recvmsg(0, {}) }.to raise_error(TypeError)
    end

    example "recvmsg validates buffer_size is positive" do
      expect { @socket.recvmsg(0, 0) }.to raise_error(ArgumentError, "buffer size must be positive")
      expect { @socket.recvmsg(0, -1) }.to raise_error(ArgumentError, "buffer size must be positive")
      expect { @socket.recvmsg(0, -100) }.to raise_error(ArgumentError, "buffer size must be positive")
    end

    example "recvmsg accepts valid buffer sizes" do
      # These should not raise ArgumentError for buffer size validation
      begin
        @socket.recvmsg(Socket::MSG_DONTWAIT, 1)      # minimum valid size
      rescue SystemCallError => e
        expect(e.message).not_to match(/buffer size must be positive/)
      end

      begin
        @socket.recvmsg(Socket::MSG_DONTWAIT, 1024)   # default size
      rescue SystemCallError => e
        expect(e.message).not_to match(/buffer size must be positive/)
      end

      begin
        @socket.recvmsg(Socket::MSG_DONTWAIT, 4096)   # larger size
      rescue SystemCallError => e
        expect(e.message).not_to match(/buffer size must be positive/)
      end
    end

    example "recvmsg with no arguments uses defaults" do
      begin
        result = @socket.recvmsg(Socket::MSG_DONTWAIT)  # Non-blocking
        expect(result).to respond_to(:message) if result
      rescue SystemCallError => e
        # Expected if no data available (EAGAIN/EWOULDBLOCK)
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe/)
      end
    end

    example "recvmsg with flags argument" do
      begin
        result = @socket.recvmsg(Socket::MSG_DONTWAIT)  # Non-blocking
        expect(result).to respond_to(:message) if result
      rescue SystemCallError => e
        # Expected if no data available
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe/)
      end
    end

    example "recvmsg with buffer size argument" do
      begin
        result = @socket.recvmsg(Socket::MSG_DONTWAIT, 2048)  # Non-blocking
        expect(result).to respond_to(:message) if result
      rescue SystemCallError => e
        # Expected if no data available
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe/)
      end
    end

    example "recvmsg returns struct with expected fields" do
      begin
        result = @socket.recvmsg(Socket::MSG_DONTWAIT)  # Non-blocking

        if result
          expect(result).to respond_to(:message)
          expect(result).to respond_to(:stream)
          expect(result).to respond_to(:flags)
          expect(result).to respond_to(:ppid)
          expect(result).to respond_to(:context)
          expect(result).to respond_to(:timetolive)
          expect(result).to respond_to(:association_id)
          expect(result).to respond_to(:notification)
          expect(result).to respond_to(:address)

          # Association ID should be valid for connected socket
          expect(result.association_id).to be >= 0
        end
      rescue SystemCallError => e
        # Expected if no data available
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe/)
      end
    end

    example "recvmsg handles notifications properly" do
      begin
        result = @socket.recvmsg(Socket::MSG_DONTWAIT)  # Non-blocking

        if result && result.notification
          # If we get a notification, validate its structure
          expect(result.message).to be_nil
          expect(result.notification).not_to be_nil
          expect(result.association_id).to be >= 0
        elsif result && result.message
          # If we get a data message, validate its structure
          expect(result.notification).to be_nil
          expect(result.message).to be_a(String)
          expect(result.association_id).to be >= 0
        end
      rescue SystemCallError => e
        # Expected - no data/notifications to receive
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe/)
      end
    end

    example "recvmsg on connected socket has valid association_id" do
      # Even if recvmsg fails, the socket should have a valid association_id
      association_id = @socket.association_id
      expect(association_id).to be >= 0

      begin
        result = @socket.recvmsg(Socket::MSG_DONTWAIT)  # Non-blocking
        if result
          expect(result.association_id).to eq(association_id)
        end
      rescue SystemCallError => e
        # Expected if no data available
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe/)
      end
    end

    example "recvmsg handles closed socket gracefully" do
      @socket.close
      expect { @socket.recvmsg }.to raise_error(IOError, "socket is closed")
    end

    example "recvmsg with different buffer sizes" do
      [512, 2048, 8192].each do |buffer_size|
        begin
          result = @socket.recvmsg(Socket::MSG_DONTWAIT, buffer_size)  # Non-blocking
          expect(result).to respond_to(:message) if result
        rescue SystemCallError => e
          # Expected - no data to receive, but should not be buffer size related
          expect(e.message).not_to match(/buffer size/)
        end
      end
    end

    example "recvmsg buffer size parameter works independently of flags" do
      # Test various combinations of flags and buffer sizes
      begin
        @socket.recvmsg(Socket::MSG_DONTWAIT, 1024)     # non-blocking, custom buffer
        @socket.recvmsg(Socket::MSG_DONTWAIT | Socket::MSG_PEEK, 2048)  # multiple flags, custom buffer
        @socket.recvmsg(Socket::MSG_DONTWAIT)           # non-blocking, default buffer
        @socket.recvmsg(0)                              # blocking (may hang), default buffer
      rescue SystemCallError => e
        # All should fail the same way (no data), not parameter errors
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe/)
      end
    end
  end
end
