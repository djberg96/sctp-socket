require_relative 'spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "set_shared_key" do
    before do
      create_connection
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

    example "set_shared_key validates key parameter type" do
      expect { @socket.set_shared_key(123, 1) }.to raise_error(TypeError)
      expect { @socket.set_shared_key(nil, 1) }.to raise_error(TypeError)
    end

    example "set_shared_key validates keynum parameter type" do
      expect { @socket.set_shared_key("key", "invalid") }.to raise_error(TypeError)
    end

    example "set_shared_key validates association_id parameter type" do
      expect { @socket.set_shared_key("key", 1, "invalid") }.to raise_error(TypeError)
    end

    example "set_shared_key rejects too many arguments" do
      expect { @socket.set_shared_key("key", 1, 0, "extra") }.to raise_error(ArgumentError)
    end

    example "set_shared_key with empty key", :linux do
      expect { @socket.set_shared_key("", 2) }.to raise_error(SystemCallError, /Invalid argument/)
    end

    example "set_shared_key with binary data" do
      result = @socket.set_shared_key("\x00\x01\x02\x03", 3)
      expect(result).to eq(@socket)
    end

    example "set_shared_key with long key" do
      result = @socket.set_shared_key("a" * 100, 4)
      expect(result).to eq(@socket)
    end

    example "set_shared_key with special key number 0" do
      result = @socket.set_shared_key("key", 0)
      expect(result).to eq(@socket)
    end

    example "set_shared_key handles closed socket gracefully" do
      @socket.close
      expect { @socket.set_shared_key("key", 1) }.to raise_error(IOError, "socket is closed")
    end

    example "set_shared_key uses socket's association_id when nil passed" do
      result = @socket.set_shared_key("testkey", 10, nil)
      expect(result).to eq(@socket)
    end

    example "set_shared_key on an unconnected socket" do
      unconnected_socket = described_class.new
      unconnected_result = unconnected_socket.set_shared_key("unconnectedkey", 51)
      expect(unconnected_result).to eq(unconnected_socket)
    end

    example "set_shared_key is compatible with auth support workflow" do
      @socket.enable_auth_support(@server.association_id)
      expect{ @socket.set_shared_key("authkey", 40) }.not_to raise_error
    end
  end

  context "delete_shared_key" do
    before do
      @socket.set_shared_key("testkey", 1)
    end

    example "delete_shared_key basic functionality" do
      result = @socket.delete_shared_key(1)
      expect(result).to eq(1)
    end

    example "delete_shared_key requires keynum argument" do
      expect { @socket.delete_shared_key }.to raise_error(ArgumentError)
    end

    example "delete_shared_key accepts optional association_id" do
      result = @socket.delete_shared_key(1, @socket.association_id)
      expect(result).to be_a(Integer)
    end

    example "Explicit nil for association_id will use socket's association", :linux do
      @socket.set_shared_key("testkey3", 3)
      result = @socket.delete_shared_key(3, nil)
      expect(result).to be_a(Integer)
    end

    example "delete_shared_key validates keynum parameter type" do
      expect { @socket.delete_shared_key("invalid") }.to raise_error(TypeError)
      expect { @socket.delete_shared_key(nil) }.to raise_error(TypeError)
    end

    example "delete_shared_key validates association_id parameter type" do
      expect { @socket.delete_shared_key(1, "invalid") }.to raise_error(TypeError)
    end

    example "delete_shared_key rejects too many arguments" do
      expect { @socket.delete_shared_key(1, 0, "extra") }.to raise_error(ArgumentError)
    end

    example "delete_shared_key with invalid keynum raises error" do
      expect{ @socket.delete_shared_key(999) }.to raise_error(SystemCallError)
    end

    example "delete_shared_key with special key number 0" do
      @socket.set_shared_key("nullkey", 0)
      expect { @socket.delete_shared_key(0) }.to raise_error(SystemCallError, /Invalid argument/)
    end

    example "delete_shared_key handles closed socket gracefully" do
      @socket.close
      expect { @socket.delete_shared_key(1) }.to raise_error(IOError, "socket is closed")
    end

    example "delete_shared_key uses socket's association_id when nil passed" do
      @socket.set_shared_key("testkey", 10, nil)
      result = @socket.delete_shared_key(10, nil)
      expect(result).to eq(10)
    end

    example "delete_shared_key on an unconnected socket" do
      unconnected_socket = described_class.new
      unconnected_socket.set_shared_key("unconnectedkey", 51)
      unconnected_result = unconnected_socket.delete_shared_key(51)
      expect(unconnected_result).to eq(51)
    end
  end
end
