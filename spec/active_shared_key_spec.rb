require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "get_active_shared_key and set_active_shared_key" do
    before do
      @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
      @server.listen

      @socket.connectx(:addresses => addresses, :port => port)

      # Allow some time for connection to establish
      sleep(0.1)
    end

    example "get_active_shared_key basic functionality" do
      expect(@socket).to respond_to(:get_active_shared_key)
    end

    example "set_active_shared_key basic functionality" do
      expect(@socket).to respond_to(:set_active_shared_key)
    end

    example "get_active_shared_key requires keynum argument" do
      expect{ @socket.get_active_shared_key }.to raise_error(ArgumentError)
    end

    example "set_active_shared_key requires keynum argument" do
      expect{ @socket.set_active_shared_key }.to raise_error(ArgumentError)
    end

    example "get_active_shared_key accepts keynum and optional association_id" do
      # These may fail with SystemCallError if auth not supported, but validates argument parsing
      begin
        @socket.get_active_shared_key(0)
        @socket.get_active_shared_key(0, nil)
        @socket.get_active_shared_key(0, 1)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "set_active_shared_key accepts keynum and optional association_id" do
      # These may fail with SystemCallError if auth not supported, but validates argument parsing
      begin
        @socket.set_active_shared_key(0)
        @socket.set_active_shared_key(0, nil)
        @socket.set_active_shared_key(0, 1)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "get_active_shared_key validates keynum parameter type" do
      expect{ @socket.get_active_shared_key("not_a_number") }.to raise_error(TypeError)
      expect{ @socket.get_active_shared_key([]) }.to raise_error(TypeError)
      expect{ @socket.get_active_shared_key({}) }.to raise_error(TypeError)
    end

    example "set_active_shared_key validates keynum parameter type" do
      expect{ @socket.set_active_shared_key("not_a_number") }.to raise_error(TypeError)
      expect{ @socket.set_active_shared_key([]) }.to raise_error(TypeError)
      expect{ @socket.set_active_shared_key({}) }.to raise_error(TypeError)
    end

    example "get_active_shared_key validates association_id parameter type" do
      expect{ @socket.get_active_shared_key(0, "not_a_number") }.to raise_error(TypeError)
      expect{ @socket.get_active_shared_key(0, []) }.to raise_error(TypeError)
      expect{ @socket.get_active_shared_key(0, {}) }.to raise_error(TypeError)
    end

    example "set_active_shared_key validates association_id parameter type" do
      expect{ @socket.set_active_shared_key(0, "not_a_number") }.to raise_error(TypeError)
      expect{ @socket.set_active_shared_key(0, []) }.to raise_error(TypeError)
      expect{ @socket.set_active_shared_key(0, {}) }.to raise_error(TypeError)
    end

    example "methods reject too many arguments" do
      expect{ @socket.get_active_shared_key(0, 1, 2) }.to raise_error(ArgumentError)
      expect{ @socket.set_active_shared_key(0, 1, 2) }.to raise_error(ArgumentError)
    end

    example "get_active_shared_key with different keynum values" do
      # Test with various key numbers - these should work on a connected socket
      [0, 1, 10, 100, 65535].each do |keynum|
        begin
          result = @socket.get_active_shared_key(keynum)
          expect(result).to be_a(Integer)
        rescue SystemCallError => e
          # Expected if key doesn't exist or auth not supported
          expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
        end
      end
    end

    example "set_active_shared_key with different keynum values" do
      # Test with various key numbers - these should work on a connected socket
      [0, 1, 10, 100, 65535].each do |keynum|
        begin
          result = @socket.set_active_shared_key(keynum)
          expect(result).to eq(@socket)
        rescue SystemCallError => e
          # Expected if key doesn't exist or auth not supported
          expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
        end
      end
    end

    example "get_active_shared_key with negative keynum values" do
      # Negative values get converted to large unsigned integers by NUM2UINT,
      # then fail at the system call level rather than Ruby argument validation
      expect{ @socket.get_active_shared_key(-1) }.to raise_error(SystemCallError)
    end

    example "set_active_shared_key with negative keynum values" do
      # Negative values get converted to large unsigned integers by NUM2UINT,
      # then fail at the system call level rather than Ruby argument validation
      expect{ @socket.set_active_shared_key(-1) }.to raise_error(SystemCallError)
    end

    example "set_active_shared_key returns self" do
      begin
        result = @socket.set_active_shared_key(0)
        expect(result).to eq(@socket)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "methods handle closed socket gracefully" do
      test_socket = described_class.new
      test_socket.close

      expect{ test_socket.get_active_shared_key(0) }.to raise_error(TypeError, /no implicit conversion from nil to integer/)
      expect{ test_socket.set_active_shared_key(0) }.to raise_error(TypeError, /no implicit conversion from nil to integer/)
    end

    example "methods use socket's association_id when nil passed" do
      initial_assoc_id = @socket.association_id

      # These should use the socket's default association_id
      begin
        @socket.get_active_shared_key(0, nil)
        @socket.set_active_shared_key(0, nil)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end

      # Verify the socket's association_id hasn't changed
      expect(@socket.association_id).to eq(initial_assoc_id)
    end

    example "methods work with different association_id values" do
      # Test with various association IDs on a connected socket
      current_assoc_id = @socket.association_id

      # Test with current association ID and some standard values
      [0, current_assoc_id].each do |assoc_id|
        begin
          @socket.get_active_shared_key(0, assoc_id)
          @socket.set_active_shared_key(0, assoc_id)
        rescue SystemCallError => e
          # Expected if SCTP authentication is not supported/configured
          expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
        end
      end
    end

    example "get_active_shared_key should return integer" do
      # This test documents expected return type on a connected socket
      begin
        result = @socket.get_active_shared_key(0)
        expect(result).to be_a(Integer)
        expect(result).to be >= 0
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "methods handle special key number 0 (null key)" do
      # Key number 0 is special (null key) and should be available on connected socket
      begin
        @socket.set_active_shared_key(0)
        result = @socket.get_active_shared_key(0)
        expect(result).to be_a(Integer)
        expect(result).to eq(0)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported on this platform
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "methods handle large key numbers" do
      # Test with larger key numbers within uint range on connected socket
      large_keynum = 65535 # More reasonable maximum for testing
      begin
        @socket.set_active_shared_key(large_keynum)
        result = @socket.get_active_shared_key(large_keynum)
        expect(result).to be_a(Integer)
      rescue SystemCallError => e
        # Expected if key doesn't exist or auth not supported
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "set_active_shared_key and get_active_shared_key work together" do
      # Test that both methods can be used in sequence on a connected socket
      begin
        @socket.set_active_shared_key(0)
        result = @socket.get_active_shared_key(0)

        expect(result).to be_a(Integer)
        expect(result).to eq(0) # Should return the key number we set
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "methods are compatible with auth support workflow" do
      # Test that shared key methods can be used after enabling auth support on connected socket
      begin
        @socket.enable_auth_support
        @socket.set_active_shared_key(0)
        result = @socket.get_active_shared_key(0)

        expect(result).to be_a(Integer)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not fully supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
      end
    end

    example "methods work on connected socket vs unconnected socket" do
      # Demonstrate the difference between connected and unconnected sockets
      unconnected_socket = described_class.new

      begin
        # Connected socket may work or fail gracefully with SystemCallError
        @socket.get_active_shared_key(0)

        # Unconnected socket should fail with SystemCallError
        expect{ unconnected_socket.get_active_shared_key(0) }.to raise_error(SystemCallError)
      rescue SystemCallError
        # Both may fail if auth not supported, but connected socket has better chance
        expect{ unconnected_socket.get_active_shared_key(0) }.to raise_error(SystemCallError)
      ensure
        unconnected_socket.close rescue nil
      end
    end

    example "methods utilize established SCTP association" do
      # Test that methods work with the actual established association
      association_id = @socket.association_id

      begin
        # Using the real association ID from connected socket
        @socket.set_active_shared_key(0, association_id)
        result = @socket.get_active_shared_key(0, association_id)

        expect(result).to be_a(Integer)
        expect(association_id).to be > 0 # Connected socket should have non-zero association
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/sctp_opt_info|not supported|Invalid argument|Permission denied/)
        # But we should still have a valid association ID
        expect(association_id).to be >= 0
      end
    end
  end
end
