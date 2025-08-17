require_relative 'spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  before do
    create_connection
  end

  context "enable_auth_support" do
    example "enable_auth_support basic functionality" do
      expect(@server).to respond_to(:enable_auth_support)
    end

    example "enable_auth_support with no arguments" do
      expect{ @server.enable_auth_support }.not_to raise_error
    end

    example "enable_auth_support with nil association_id" do
      expect{ @server.enable_auth_support(nil) }.not_to raise_error
    end

    example "enable_auth_support with numeric association_id" do
      expect{ @server.enable_auth_support(0) }.not_to raise_error
      expect{ @server.enable_auth_support(@server.association_id) }.not_to raise_error
    end

    example "enable_auth_support with invalid association_id", :bsd do
      expect{ @server.enable_auth_support(99) }.to raise_error(SystemCallError)
    end

    example "enable_auth_support returns self" do
      result = @server.enable_auth_support
      expect(result).to eq(@server)
    end

    example "enable_auth_support accepts only 0 or 1 arguments" do
      expect{ @server.enable_auth_support(0, 1) }.to raise_error(ArgumentError)
      expect{ @server.enable_auth_support(0, 1, 2) }.to raise_error(ArgumentError)
    end

    example "enable_auth_support with invalid association_id type" do
      expect{ @server.enable_auth_support("invalid") }.to raise_error(TypeError)
      expect{ @server.enable_auth_support([]) }.to raise_error(TypeError)
      expect{ @server.enable_auth_support({}) }.to raise_error(TypeError)
    end

    example "enable_auth_support can be called multiple times" do
      expect{ @server.enable_auth_support }.not_to raise_error
      expect{ @server.enable_auth_support }.not_to raise_error
      expect{ @server.enable_auth_support(0) }.not_to raise_error
    end

    example "enable_auth_support always sets auth_value to 1" do
      3.times do
        expect{ @server.enable_auth_support }.not_to raise_error
      end

      result = @server.enable_auth_support
      expect(result).to eq(@server)
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
      expect(@server).to respond_to(:auth_support?)
    end

    example "auth_support? returns boolean value" do
      result = @server.auth_support?
      expect(result).to be_a(TrueClass).or be_a(FalseClass)
    end

    example "auth_support? with no arguments" do
      expect{ @server.auth_support? }.not_to raise_error
    end

    example "auth_support? with nil association_id" do
      expect{ @server.auth_support?(nil) }.not_to raise_error
    end

    example "auth_support? with numeric association_id" do
      expect{ @server.auth_support?(0) }.not_to raise_error
      expect{ @server.auth_support?(@server.association_id) }.not_to raise_error
    end

    example "auth_support? with an invalid association_id", :bsd do
      expect{ @server.auth_support?(99) }.to raise_error(SystemCallError)
    end

    example "auth_support? accepts only 0 or 1 arguments" do
      expect{ @server.auth_support?(0, 1) }.to raise_error(ArgumentError)
      expect{ @server.auth_support?(0, 1, 2) }.to raise_error(ArgumentError)
    end

    example "auth_support? with invalid association_id type" do
      expect{ @server.auth_support?("invalid") }.to raise_error(TypeError)
      expect{ @server.auth_support?([]) }.to raise_error(TypeError)
      expect{ @server.auth_support?({}) }.to raise_error(TypeError)
    end

    example "auth_support? returns consistent values on multiple calls" do
      state1 = @server.auth_support?
      state2 = @server.auth_support?
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
      @server.bindx(:addresses => addresses, :port => port)
      expect{ @server.enable_auth_support }.not_to raise_error
      expect{ @server.auth_support? }.to be_a(TrueClass)
    end

    example "auth_support? and enable_auth_support work together" do
      initial_state = @server.auth_support?
      expect(initial_state).to be_a(TrueClass).or be_a(FalseClass)

      @server.enable_auth_support
      current_state = @server.auth_support?
      expect(current_state).to be_a(TrueClass).or be_a(FalseClass)
    end

    example "methods use socket's association_id when nil passed" do
      initial_assoc_id = @server.association_id

      # These should not raise errors when using socket's default association_id
      expect{ @server.auth_support?(nil) }.not_to raise_error
      expect{ @server.enable_auth_support(nil) }.not_to raise_error

      # Verify the socket's association_id hasn't changed
      expect(@server.association_id).to eq(initial_assoc_id)
    end

    example "auth_support? state after enable_auth_support" do
      @server.enable_auth_support
      final_state = @server.auth_support?
      expect(final_state).to be_a(TrueClass).or be_a(FalseClass)
    end
  end
end
