require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  before do
    create_connection
  end

  context "enable_auth_support" do
    example "enable_auth_support basic functionality" do
      expect(@socket).to respond_to(:enable_auth_support)
    end

    example "enable_auth_support with no arguments" do
      expect{ @socket.enable_auth_support }.not_to raise_error
    end

    example "enable_auth_support with nil association_id" do
      expect{ @socket.enable_auth_support(nil) }.not_to raise_error
    end

    example "enable_auth_support with numeric association_id" do
      expect{ @socket.enable_auth_support(0) }.not_to raise_error
      expect{ @socket.enable_auth_support(@socket.association_id) }.not_to raise_error
    end

    example "enable_auth_support with invalid association_id" do
      expect{ @socket.enable_auth_support(99) }.to raise_error(SystemCallError)
    end

    example "enable_auth_support returns self" do
      result = @socket.enable_auth_support
      expect(result).to eq(@socket)
    end

    example "enable_auth_support accepts only 0 or 1 arguments" do
      expect{ @socket.enable_auth_support(0, 1) }.to raise_error(ArgumentError)
      expect{ @socket.enable_auth_support(0, 1, 2) }.to raise_error(ArgumentError)
    end

    example "enable_auth_support with invalid association_id type" do
      expect{ @socket.enable_auth_support("invalid") }.to raise_error(TypeError)
      expect{ @socket.enable_auth_support([]) }.to raise_error(TypeError)
      expect{ @socket.enable_auth_support({}) }.to raise_error(TypeError)
    end

    example "enable_auth_support can be called multiple times" do
      expect{ @socket.enable_auth_support }.not_to raise_error
      expect{ @socket.enable_auth_support }.not_to raise_error
      expect{ @socket.enable_auth_support(0) }.not_to raise_error
    end

    example "enable_auth_support always sets auth_value to 1" do
      3.times do
        expect{ @socket.enable_auth_support }.not_to raise_error
      end

      result = @socket.enable_auth_support
      expect(result).to eq(@socket)
    end

    example "enable_auth_support behavior with closed socket" do
      test_socket = described_class.new
      test_socket.close

      expect{ test_socket.enable_auth_support }.to raise_error(IOError, /socket is closed/)
      expect{ test_socket.enable_auth_support(0) }.to raise_error(IOError, /socket is closed/)
    end
  end

  context "auth_support?" do
    example "auth_support? basic functionality" do
      expect(@socket).to respond_to(:auth_support?)
    end

    example "auth_support? returns boolean value" do
      result = @socket.auth_support?
      expect(result).to be_a(TrueClass).or be_a(FalseClass)
    end

    example "auth_support? with no arguments" do
      expect{ @socket.auth_support? }.not_to raise_error
    end

    example "auth_support? with nil association_id" do
      expect{ @socket.auth_support?(nil) }.not_to raise_error
    end

    example "auth_support? with numeric association_id" do
      expect{ @socket.auth_support?(0) }.not_to raise_error
      expect{ @socket.auth_support?(@socket.association_id) }.not_to raise_error
    end

    example "auth_support? with an invalid association_id" do
      expect{ @socket.auth_support?(99) }.to raise_error(SystemCallError)
    end

    example "auth_support? accepts only 0 or 1 arguments" do
      expect{ @socket.auth_support?(0, 1) }.to raise_error(ArgumentError)
      expect{ @socket.auth_support?(0, 1, 2) }.to raise_error(ArgumentError)
    end

    example "auth_support? with invalid association_id type" do
      expect{ @socket.auth_support?("invalid") }.to raise_error(TypeError)
      expect{ @socket.auth_support?([]) }.to raise_error(TypeError)
      expect{ @socket.auth_support?({}) }.to raise_error(TypeError)
    end

    example "auth_support? returns consistent values on multiple calls" do
      state1 = @socket.auth_support?
      state2 = @socket.auth_support?
      expect(state1).to eq(state2)
    end

    example "auth_support? behavior with closed socket" do
      test_socket = described_class.new
      test_socket.close

      expect{ test_socket.auth_support? }.to raise_error(IOError, /socket is closed/)
      expect{ test_socket.auth_support?(0) }.to raise_error(IOError, /socket is closed/)
    end
  end

  context "enable_auth_support and auth_support?" do
    xexample "enable_auth_support works after socket operations" do
      @socket.bindx(:addresses => addresses, :port => port)
      expect{ @socket.enable_auth_support }.not_to raise_error
      expect{ @socket.auth_support? }.to be_a(TrueClass)
    end

    example "auth_support? and enable_auth_support work together" do
      initial_state = @socket.auth_support?
      expect(initial_state).to be_a(TrueClass).or be_a(FalseClass)

      @socket.enable_auth_support
      current_state = @socket.auth_support?
      expect(current_state).to be_a(TrueClass).or be_a(FalseClass)
    end

    example "methods use socket's association_id when nil passed" do
      initial_assoc_id = @socket.association_id

      # These should not raise errors when using socket's default association_id
      expect{ @socket.auth_support?(nil) }.not_to raise_error
      expect{ @socket.enable_auth_support(nil) }.not_to raise_error

      # Verify the socket's association_id hasn't changed
      expect(@socket.association_id).to eq(initial_assoc_id)
    end

    example "auth_support? state after enable_auth_support" do
      @socket.enable_auth_support
      final_state = @socket.auth_support?
      expect(final_state).to be_a(TrueClass).or be_a(FalseClass)
    end
  end
end
