require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "map_ipv4= and map_ipv4?" do
    example "map_ipv4= basic functionality" do
      expect(@socket).to respond_to(:map_ipv4=)
    end

     example "map_ipv4? basic functionality" do
      expect(@socket).to respond_to(:map_ipv4?)
     end

    example "map_ipv4? returns boolean value" do
      result = @socket.map_ipv4?
      expect(result).to be_a(TrueClass).or be_a(FalseClass)
    end

    example "map_ipv4? does not accept any arguments" do
      expect{ @socket.map_ipv4?(true) }.to raise_error(ArgumentError)
      expect{ @socket.map_ipv4?(false) }.to raise_error(ArgumentError)
    end

    example "map_ipv4= accepts boolean values" do
      expect{ @socket.map_ipv4 = true }.not_to raise_error
      expect{ @socket.map_ipv4 = false }.not_to raise_error
    end

    example "map_ipv4= accepts truthy values" do
      expect{ @socket.map_ipv4 = 1 }.not_to raise_error
      expect{ @socket.map_ipv4 = "true" }.not_to raise_error
    end

    example "map_ipv4= accepts falsey values" do
      expect{ @socket.map_ipv4 = 0 }.not_to raise_error
      expect{ @socket.map_ipv4 = nil }.not_to raise_error
      expect{ @socket.map_ipv4 = false }.not_to raise_error
    end

    example "map_ipv4 setting persists and can be retrieved" do
      @socket.map_ipv4 = true
      expect(@socket.map_ipv4?).to eq(true)

      @socket.map_ipv4 = false
      expect(@socket.map_ipv4?).to eq(false)
    end

    example "map_ipv4 can be toggled multiple times" do
      initial_state = @socket.map_ipv4?

      @socket.map_ipv4 = !initial_state
      expect(@socket.map_ipv4?).to eq(!initial_state)

      @socket.map_ipv4 = initial_state
      expect(@socket.map_ipv4?).to eq(initial_state)
    end

    example "map_ipv4? default state is consistent" do
      # Get the default state multiple times to ensure consistency
      state1 = @socket.map_ipv4?
      state2 = @socket.map_ipv4?
      expect(state1).to eq(state2)
    end

    example "map_ipv4= can be called multiple times" do
      expect{ @socket.map_ipv4 = true }.not_to raise_error
      expect{ @socket.map_ipv4 = false }.not_to raise_error
      expect{ @socket.map_ipv4 = true }.not_to raise_error
    end

    example "map_ipv4= works with different socket types" do
      socket_inet6 = described_class.new(Socket::AF_INET6)
      expect{ socket_inet6.map_ipv4 = true }.not_to raise_error
      expect{ socket_inet6.map_ipv4 = false }.not_to raise_error
      expect(socket_inet6.map_ipv4?).to be_a(TrueClass).or be_a(FalseClass)
      socket_inet6.close(linger: 0)
    end
  end
end
