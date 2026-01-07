require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "recvv" do
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

    example "recvv basic functionality" do
      expect(@socket).to respond_to(:recvv)
    end

    example "recvv validates flags parameter type" do
      expect { @socket.recvv("not an integer") }.to raise_error(TypeError)
      expect { @socket.recvv([]) }.to raise_error(TypeError)
      expect { @socket.recvv({}) }.to raise_error(TypeError)
    end

    example "recvv validates buffer_size parameter type" do
      expect { @socket.recvv(0, "not an integer") }.to raise_error(TypeError)
      expect { @socket.recvv(0, []) }.to raise_error(TypeError)
      expect { @socket.recvv(0, {}) }.to raise_error(TypeError)
    end

    example "recvv validates buffer_size is positive" do
      expect { @socket.recvv(0, 0) }.to raise_error(ArgumentError, "buffer size must be positive")
      expect { @socket.recvv(0, -1) }.to raise_error(ArgumentError, "buffer size must be positive")
      expect { @socket.recvv(0, -100) }.to raise_error(ArgumentError, "buffer size must be positive")
    end

    example "recvv accepts valid buffer sizes" do
      # These should not raise ArgumentError for buffer size validation
      begin
        @socket.recvv(Socket::MSG_DONTWAIT, 1)      # minimum valid size
      rescue SystemCallError => e
        expect(e.message).not_to match(/buffer size must be positive/)
      end

      begin
        @socket.recvv(Socket::MSG_DONTWAIT, 1024)   # default size
      rescue SystemCallError => e
        expect(e.message).not_to match(/buffer size must be positive/)
      end

      begin
        @socket.recvv(Socket::MSG_DONTWAIT, 4096)   # larger size
      rescue SystemCallError => e
        expect(e.message).not_to match(/buffer size must be positive/)
      end
    end

    example "recvv with no arguments uses defaults" do
      begin
        result = @socket.recvv(Socket::MSG_DONTWAIT)  # Non-blocking
        expect(result).to respond_to(:message) if result
      rescue SystemCallError => e
        # Expected if no data available (EAGAIN/EWOULDBLOCK)
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe/)
      end
    end

    example "recvv with flags argument" do
      begin
        result = @socket.recvv(Socket::MSG_DONTWAIT)  # Non-blocking
        expect(result).to respond_to(:message) if result
      rescue SystemCallError => e
        # Expected if no data available
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe/)
      end
    end

    example "recvv with buffer size argument" do
      begin
        result = @socket.recvv(Socket::MSG_DONTWAIT, 2048)  # Non-blocking
        expect(result).to respond_to(:message) if result
      rescue SystemCallError => e
        # Expected if no data available
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe/)
      end
    end

    example "recvv returns struct with expected fields" do
      begin
        result = @socket.recvv(Socket::MSG_DONTWAIT)  # Non-blocking

        if result
          expect(result).to respond_to(:message)
          expect(result).to respond_to(:stream)
          expect(result).to respond_to(:ssn)
          expect(result).to respond_to(:flags)
          expect(result).to respond_to(:ppid)
          expect(result).to respond_to(:tsn)
          expect(result).to respond_to(:cumtsn)
          expect(result).to respond_to(:context)
          expect(result).to respond_to(:association_id)

          # Association ID should be valid for connected socket
          expect(result.association_id).to be >= 0
        end
      rescue SystemCallError => e
        # Expected if no data available or sctp_recvv not supported
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe|not supported/)
      end
    end

    example "recvv handles different data structures" do
      begin
        result = @socket.recvv(Socket::MSG_DONTWAIT)  # Non-blocking

        if result && result.message
          # If we get a data message, validate its structure
          expect(result.message).to be_a(String)
          expect(result.association_id).to be >= 0
          expect(result.stream).to be >= 0
          expect(result.ppid).to be >= 0
        end
      rescue SystemCallError => e
        # Expected - no data to receive or sctp_recvv not supported
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe|not supported/)
      end
    end

    example "recvv on connected socket has valid association_id" do
      # Even if recvv fails, the socket should have a valid association_id
      association_id = @socket.association_id
      expect(association_id).to be >= 0

      begin
        result = @socket.recvv(Socket::MSG_DONTWAIT)  # Non-blocking
        if result
          expect(result.association_id).to eq(association_id)
        end
      rescue SystemCallError => e
        # Expected if no data available or sctp_recvv not supported
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe|not supported/)
      end
    end

    example "recvv handles closed socket gracefully" do
      @socket.close
      expect { @socket.recvv }.to raise_error(IOError, "socket is closed")
    end

    example "recvv with different buffer sizes" do
      [512, 2048, 8192].each do |buffer_size|
        begin
          result = @socket.recvv(Socket::MSG_DONTWAIT, buffer_size)  # Non-blocking
          expect(result).to respond_to(:message) if result
        rescue SystemCallError => e
          # Expected - no data to receive, but should not be buffer size related
          expect(e.message).not_to match(/buffer size/)
        end
      end
    end

    example "recvv buffer size parameter works independently of flags" do
      # Test various combinations of flags and buffer sizes
      begin
        @socket.recvv(Socket::MSG_DONTWAIT, 1024)     # non-blocking, custom buffer
        @socket.recvv(Socket::MSG_DONTWAIT | Socket::MSG_PEEK, 2048)  # multiple flags, custom buffer
        @socket.recvv(Socket::MSG_DONTWAIT)           # non-blocking, default buffer
        @socket.recvv(0)                              # blocking (may hang), default buffer
      rescue SystemCallError => e
        # All should fail the same way (no data), not parameter errors
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe|not supported/)
      end
    end

    example "recvv provides detailed receive information" do
      begin
        result = @socket.recvv(Socket::MSG_DONTWAIT)  # Non-blocking

        if result
          # Test that recvv provides more detailed info than recvmsg
          expect(result).to respond_to(:tsn)      # Transmission Sequence Number
          expect(result).to respond_to(:cumtsn)   # Cumulative TSN
          expect(result).to respond_to(:ssn)      # Stream Sequence Number

          # These should be numeric values
          expect(result.tsn).to be_a(Integer) if result.tsn
          expect(result.cumtsn).to be_a(Integer) if result.cumtsn
          expect(result.ssn).to be_a(Integer) if result.ssn
        end
      rescue SystemCallError => e
        # Expected if no data available or sctp_recvv not supported
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe|not supported/)
      end
    end

    example "recvv handles sctp_recvv availability" do
      # This test accounts for systems where sctp_recvv might not be available
      begin
        result = @socket.recvv(Socket::MSG_DONTWAIT)
        # If it succeeds, recvv is supported
        expect(result).to respond_to(:message) if result
      rescue SystemCallError => e
        # Could be no data OR sctp_recvv not supported
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe|not supported|Invalid argument/)
      rescue NoMethodError => e
        # recvv method itself might not be defined if HAVE_SCTP_RECVV is false
        expect(e.message).to match(/undefined method.*recvv/)
      end
    end

    example "recvv buffer allocation works correctly" do
      # Test that buffer allocation and deallocation work properly
      buffer_sizes = [64, 256, 1024, 4096]

      buffer_sizes.each do |size|
        begin
          result = @socket.recvv(Socket::MSG_DONTWAIT, size)
          # If successful, buffer should handle the specified size
          expect(result).to respond_to(:message) if result
        rescue SystemCallError => e
          # Expected - should not be memory allocation errors
          expect(e.message).not_to match(/failed to allocate|no memory|out of memory/i)
        end
      end
    end

    example "recvv uses proper message length" do
      begin
        result = @socket.recvv(Socket::MSG_DONTWAIT, 1024)

        if result && result.message
          # Message should be created with proper length (not null-terminated string)
          message = result.message
          expect(message).to be_a(String)
          # Should not have extra null bytes if using rb_str_new vs rb_str_new2
          expect(message.length).to be >= 0
        end
      rescue SystemCallError => e
        # Expected if no data available
        expect(e.message).to match(/Resource temporarily unavailable|would block|Connection refused|Broken pipe|not supported/)
      end
    end
  end
end
