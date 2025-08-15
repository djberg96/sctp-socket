require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "set_shared_key" do
    before do
      create_connection
      @socket.enable_auth_support(@server.association_id)
    end

    example "set_shared_key basic functionality" do
      result = @socket.set_shared_key("testkey")
      expect(result).to eq(@socket)
    end

    example "set_shared_key accepts optional keynum" do
      result = @socket.set_shared_key("testkey", 1)
      expect(result).to eq(@socket)
    end

    example "set_shared_key accepts optional association_id" do
      result = @socket.set_shared_key("testkey", 1, @socket.association_id)
      expect(result).to eq(@socket)
    end

    example "set_shared_key requires key argument" do
      expect { @socket.set_shared_key }.to raise_error(ArgumentError)
    end
  end

  context "delete_shared_key" do
    before do
      @socket.set_shared_key("testkey", 1)
    end

    example "delete_shared_key basic functionality" do
      result = @socket.delete_shared_key(1)
      expect(result).to be_a(Integer)
    end

    example "delete_shared_key requires keynum argument" do
      expect { @socket.delete_shared_key }.to raise_error(ArgumentError)
    end
  end

=begin

    example "delete_shared_key accepts keynum and optional association_id" do
      begin
        # Test with association_id
        result = @socket.delete_shared_key(1, @socket.association_id)
        expect(result).to be_a(Integer)

        # Test without association_id (should use socket's association_id)
        result = @socket.delete_shared_key(2)
        expect(result).to be_a(Integer)

        # Test with nil association_id (should use socket's association_id)
        result = @socket.delete_shared_key(3, nil)
        expect(result).to be_a(Integer)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/setsockopt|not supported|Invalid argument|Permission denied/)
      end
    end

    example "set_shared_key validates key parameter type" do
      expect { @socket.set_shared_key(123, 1) }.to raise_error(TypeError)
      expect { @socket.set_shared_key(nil, 1) }.to raise_error(TypeError)
    end

    example "set_shared_key validates keynum parameter type" do
      expect { @socket.set_shared_key("key", "invalid") }.to raise_error(TypeError)
      # nil is valid as keynum defaults to 1
      begin
        @socket.set_shared_key("key", nil)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/setsockopt|not supported|Invalid argument|Permission denied/)
      end
    end

    example "delete_shared_key validates keynum parameter type" do
      expect { @socket.delete_shared_key("invalid") }.to raise_error(TypeError)
      expect { @socket.delete_shared_key(nil) }.to raise_error(TypeError)
    end

    example "set_shared_key validates association_id parameter type" do
      expect { @socket.set_shared_key("key", 1, "invalid") }.to raise_error(TypeError)
    end

    example "delete_shared_key validates association_id parameter type" do
      expect { @socket.delete_shared_key(1, "invalid") }.to raise_error(TypeError)
    end

    example "methods reject too many arguments" do
      expect { @socket.set_shared_key("key", 1, 0, "extra") }.to raise_error(ArgumentError)
      expect { @socket.delete_shared_key(1, 0, "extra") }.to raise_error(ArgumentError)
    end

    example "set_shared_key with different key values" do
      begin
        # Test with regular string key
        result = @socket.set_shared_key("regularkey", 1)
        expect(result).to eq(@socket)

        # Test with empty string (null key)
        result = @socket.set_shared_key("", 2)
        expect(result).to eq(@socket)

        # Test with binary data
        result = @socket.set_shared_key("\x00\x01\x02\x03", 3)
        expect(result).to eq(@socket)

        # Test with longer key
        result = @socket.set_shared_key("a" * 100, 4)
        expect(result).to eq(@socket)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/setsockopt|not supported|Invalid argument|Permission denied/)
      end
    end

    example "delete_shared_key with different keynum values" do
      begin
        # Test with various key numbers
        [1, 2, 10, 100].each do |keynum|
          result = @socket.delete_shared_key(keynum)
          expect(result).to be_a(Integer)
        end
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/setsockopt|not supported|Invalid argument|Permission denied/)
      end
    end

    example "set_shared_key with special key number 0 (null key)" do
      begin
        result = @socket.set_shared_key("", 0)
        expect(result).to eq(@socket)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/setsockopt|not supported|Invalid argument|Permission denied/)
      end
    end

    example "delete_shared_key with special key number 0 (disables null key)" do
      begin
        result = @socket.delete_shared_key(0)
        expect(result).to be_a(Integer)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/setsockopt|not supported|Invalid argument|Permission denied/)
      end
    end

    example "set_shared_key returns self" do
      begin
        result = @socket.set_shared_key("testkey", 5)
        expect(result).to equal(@socket)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/setsockopt|not supported|Invalid argument|Permission denied/)
      end
    end

    example "delete_shared_key returns integer key number" do
      begin
        result = @socket.delete_shared_key(5)
        expect(result).to be_a(Integer)
        expect(result).to eq(5)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/setsockopt|not supported|Invalid argument|Permission denied/)
      end
    end

    example "methods handle closed socket gracefully" do
      @socket.close
      expect { @socket.set_shared_key("key", 1) }.to raise_error(TypeError, /no implicit conversion from nil to integer/)
      expect { @socket.delete_shared_key(1) }.to raise_error(TypeError, /no implicit conversion from nil to integer/)
    end

    example "methods use socket's association_id when nil passed" do
      begin
        association_id = @socket.association_id

        # Both methods should work with nil association_id
        result1 = @socket.set_shared_key("testkey", 10, nil)
        expect(result1).to eq(@socket)

        result2 = @socket.delete_shared_key(10, nil)
        expect(result2).to be_a(Integer)

        expect(association_id).to be >= 0
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/setsockopt|not supported|Invalid argument|Permission denied/)
      end
    end

    example "methods work with different association_id values" do
      begin
        association_id = @socket.association_id

        # Test with explicit association_id
        result1 = @socket.set_shared_key("testkey", 20, association_id)
        expect(result1).to eq(@socket)

        result2 = @socket.delete_shared_key(20, association_id)
        expect(result2).to be_a(Integer)

        # Test with 0 (endpoint level)
        result3 = @socket.set_shared_key("endpointkey", 21, 0)
        expect(result3).to eq(@socket)

        result4 = @socket.delete_shared_key(21, 0)
        expect(result4).to be_a(Integer)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/setsockopt|not supported|Invalid argument|Permission denied/)
      end
    end

    example "set_shared_key and delete_shared_key work together" do
      begin
        # Set a key
        @socket.set_shared_key("workflowkey", 30)

        # Delete the same key
        result = @socket.delete_shared_key(30)
        expect(result).to eq(30)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/setsockopt|not supported|Invalid argument|Permission denied/)
      end
    end

    example "methods are compatible with auth support workflow" do
      begin
        # Enable auth support first
        @socket.enable_auth_support

        # Set a shared key
        @socket.set_shared_key("authkey", 40)

        # Try to set it as active (might fail if key management not fully supported)
        @socket.set_active_shared_key(40)

        # Clean up
        @socket.delete_shared_key(40)
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/setsockopt|not supported|Invalid argument|Permission denied/)
      end
    end

    example "methods work on connected socket vs unconnected socket" do
      begin
        # Test on connected socket (our @socket)
        connected_result = @socket.set_shared_key("connectedkey", 50)
        expect(connected_result).to eq(@socket)

        # Test on unconnected socket
        unconnected_socket = described_class.new
        unconnected_result = unconnected_socket.set_shared_key("unconnectedkey", 51)
        expect(unconnected_result).to eq(unconnected_socket)

        # Clean up
        @socket.delete_shared_key(50)
        unconnected_socket.delete_shared_key(51)
        unconnected_socket.close
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/setsockopt|not supported|Invalid argument|Permission denied/)
      end
    end

    example "methods utilize established SCTP association" do
      begin
        # Test that methods work with the actual established association
        association_id = @socket.association_id

        # Set key using the real association ID from connected socket
        @socket.set_shared_key("associationkey", 60, association_id)

        # Delete key using the real association ID
        result = @socket.delete_shared_key(60, association_id)
        expect(result).to eq(60)
        expect(association_id).to be > 0 # Connected socket should have non-zero association
      rescue SystemCallError => e
        # Expected if SCTP authentication is not supported/configured
        expect(e.message).to match(/setsockopt|not supported|Invalid argument|Permission denied/)
        # But we should still have a valid association ID
        association_id = @socket.association_id
        expect(association_id).to be >= 0
      end
    end
=end
end
