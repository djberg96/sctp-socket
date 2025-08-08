require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "nodelay? and nodelay=" do
    example "nodelay? basic functionality" do
      expect(@socket).to respond_to(:nodelay?)
    end

    example "nodelay= basic functionality" do
      expect(@socket).to respond_to(:nodelay=)
    end

    example "nodelay? returns boolean value" do
      result = @socket.nodelay?
      expect(result).to be_a(TrueClass).or be_a(FalseClass)
    end

    example "nodelay= accepts boolean values" do
      expect{ @socket.nodelay = true }.not_to raise_error
      expect{ @socket.nodelay = false }.not_to raise_error
    end

    example "nodelay= accepts nil (treated as false)" do
      expect{ @socket.nodelay = nil }.not_to raise_error
      expect(@socket.nodelay?).to eq(false)
    end

    example "nodelay= accepts truthy values" do
      expect{ @socket.nodelay = 1 }.not_to raise_error
      expect(@socket.nodelay?).to eq(true)

      expect{ @socket.nodelay = "true" }.not_to raise_error
      expect(@socket.nodelay?).to eq(true)
    end

    example "nodelay= accepts nil as falsey value" do
      expect{ @socket.nodelay = nil }.not_to raise_error
      expect(@socket.nodelay?).to eq(false)
    end

    example "nodelay= returns boolean value" do
      result = @socket.nodelay = true
      expect(result).to be_a(TrueClass).or be_a(FalseClass)

      result = @socket.nodelay = false
      expect(result).to be_a(TrueClass).or be_a(FalseClass)
    end

    example "nodelay setting persists and can be retrieved" do
      @socket.nodelay = true
      expect(@socket.nodelay?).to eq(true)

      @socket.nodelay = false
      expect(@socket.nodelay?).to eq(false)
    end

    example "nodelay? does not accept any arguments" do
      expect{ @socket.nodelay?(true) }.to raise_error(ArgumentError)
      expect{ @socket.nodelay?(false) }.to raise_error(ArgumentError)
    end

    example "nodelay= requires exactly one argument" do
      expect{ @socket.send(:nodelay=, true, false) }.to raise_error(ArgumentError)
    end

    example "nodelay can be toggled multiple times" do
      initial_state = @socket.nodelay?

      @socket.nodelay = !initial_state
      expect(@socket.nodelay?).to eq(!initial_state)

      @socket.nodelay = initial_state
      expect(@socket.nodelay?).to eq(initial_state)
    end

    example "nodelay default state is consistent" do
      # Get the default state multiple times to ensure consistency
      state1 = @socket.nodelay?
      state2 = @socket.nodelay?
      expect(state1).to eq(state2)
    end
  end
end
