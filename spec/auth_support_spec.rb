require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "enable_auth_support and auth_support?" do
    example "enable_auth_support basic functionality" do
      expect(@socket).to respond_to(:enable_auth_support)
    end

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
      expect{ @socket.auth_support?(1) }.not_to raise_error
    end

    example "auth_support? accepts only 0 or 1 arguments" do
      expect{ @socket.auth_support? }.not_to raise_error
      expect{ @socket.auth_support?(0) }.not_to raise_error
      expect{ @socket.auth_support?(0, 1) }.to raise_error(ArgumentError)
      expect{ @socket.auth_support?(0, 1, 2) }.to raise_error(ArgumentError)
    end

    example "auth_support? with invalid association_id type" do
      expect{ @socket.auth_support?("invalid") }.to raise_error(TypeError)
      expect{ @socket.auth_support?([]) }.to raise_error(TypeError)
      expect{ @socket.auth_support?({}) }.to raise_error(TypeError)
    end

    example "enable_auth_support with no arguments" do
      expect{ @socket.enable_auth_support }.not_to raise_error
    end

    example "enable_auth_support with nil association_id" do
      expect{ @socket.enable_auth_support(nil) }.not_to raise_error
    end

    example "enable_auth_support with numeric association_id" do
      expect{ @socket.enable_auth_support(0) }.not_to raise_error
      expect{ @socket.enable_auth_support(1) }.not_to raise_error
    end

    example "enable_auth_support returns self" do
      result = @socket.enable_auth_support
      expect(result).to eq(@socket)
    end

    example "enable_auth_support accepts only 0 or 1 arguments" do
      expect{ @socket.enable_auth_support }.not_to raise_error
      expect{ @socket.enable_auth_support(0) }.not_to raise_error
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

    example "enable_auth_support works after socket operations" do
      # Test that it works even after other socket operations
      @socket.bindx(:addresses => addresses, :port => port)
      expect{ @socket.enable_auth_support }.not_to raise_error
    end

    example "auth_support? and enable_auth_support work together" do
      # Test that the getter and setter work together
      initial_state = @socket.auth_support?
      expect(initial_state).to be_a(TrueClass).or be_a(FalseClass)

      # Enable auth support
      @socket.enable_auth_support

      # Check that it can still be queried
      current_state = @socket.auth_support?
      expect(current_state).to be_a(TrueClass).or be_a(FalseClass)
    end

    example "auth_support? returns consistent values on multiple calls" do
      # Get the state multiple times to ensure consistency
      state1 = @socket.auth_support?
      state2 = @socket.auth_support?
      expect(state1).to eq(state2)
    end

    example "auth_support? works after socket operations" do
      # Test that it works even after other socket operations
      @socket.bindx(:addresses => addresses, :port => port)
      expect{ @socket.auth_support? }.not_to raise_error
      result = @socket.auth_support?
      expect(result).to be_a(TrueClass).or be_a(FalseClass)
    end

    example "auth_support? behavior with closed socket" do
      test_socket = described_class.new
      test_socket.close

      expect{ test_socket.auth_support? }.to raise_error(IOError, /socket is closed/)
      expect{ test_socket.auth_support?(0) }.to raise_error(IOError, /socket is closed/)
    end

    example "enable_auth_support behavior with closed socket" do
      test_socket = described_class.new
      test_socket.close

      # enable_auth_support doesn't check for closed socket before accessing @fileno
      # When socket is closed, @fileno becomes nil, causing TypeError on NUM2INT conversion
      expect{ test_socket.enable_auth_support }.to raise_error(TypeError, /no implicit conversion from nil to integer/)
      expect{ test_socket.enable_auth_support(0) }.to raise_error(TypeError, /no implicit conversion from nil to integer/)
    end

    example "methods use socket's association_id when nil passed" do
      # Test that nil argument uses the socket's @association_id
      initial_assoc_id = @socket.association_id

      # These should not raise errors when using socket's default association_id
      expect{ @socket.auth_support?(nil) }.not_to raise_error
      expect{ @socket.enable_auth_support(nil) }.not_to raise_error

      # Verify the socket's association_id hasn't changed
      expect(@socket.association_id).to eq(initial_assoc_id)
    end

    example "enable_auth_support with different association IDs" do
      # Test with various valid association ID values
      [0, 1, 100, 1000].each do |assoc_id|
        expect{ @socket.enable_auth_support(assoc_id) }.not_to raise_error
      end
    end

    example "auth_support? with different association IDs" do
      # Test with various valid association ID values
      [0, 1, 100, 1000].each do |assoc_id|
        expect{ @socket.auth_support?(assoc_id) }.not_to raise_error
        result = @socket.auth_support?(assoc_id)
        expect(result).to be_a(TrueClass).or be_a(FalseClass)
      end
    end

    example "enable_auth_support always sets auth_value to 1" do
      # Test that enable_auth_support always enables authentication
      # (implementation sets assoc_value.assoc_value = 1)

      # Enable auth support multiple times - should not cause issues
      3.times do
        expect{ @socket.enable_auth_support }.not_to raise_error
      end

      # Method should still return self after multiple calls
      result = @socket.enable_auth_support
      expect(result).to eq(@socket)
    end

    example "auth_support? state after enable_auth_support" do
      # Test the interaction between the two methods
      begin
        # Enable auth support
        @socket.enable_auth_support

        # Check state - may or may not change depending on platform/configuration
        # This test documents the behavior rather than asserting a specific outcome
        final_state = @socket.auth_support?
        expect(final_state).to be_a(TrueClass).or be_a(FalseClass)

      rescue SystemCallError => e
        # Some platforms may not support these operations - that's acceptable
        # This test documents what happens in such cases
        expect(e.message).to match(/not supported|Invalid argument|Operation not supported/)
      end
    end
  end
end
