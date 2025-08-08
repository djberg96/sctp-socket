require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "get_init_msg" do
    example "get_init_msg basic functionality" do
      expect(@socket).to respond_to(:get_init_msg)
    end

    example "get_init_msg returns expected struct type" do
      init_msg = @socket.get_init_msg
      expect(init_msg).to be_a(Struct)
      expect(init_msg.class.name).to match(/InitMsg/)
    end

    example "get_init_msg returns struct with expected members" do
      init_msg = @socket.get_init_msg
      expect(init_msg).to respond_to(:num_ostreams)
      expect(init_msg).to respond_to(:max_instreams)
      expect(init_msg).to respond_to(:max_attempts)
      expect(init_msg).to respond_to(:max_init_timeout)
    end

    example "get_init_msg returns struct with expected value types" do
      init_msg = @socket.get_init_msg
      expect(init_msg.num_ostreams).to be_a(Integer)
      expect(init_msg.max_instreams).to be_a(Integer)
      expect(init_msg.max_attempts).to be_a(Integer)
      expect(init_msg.max_init_timeout).to be_a(Integer)
    end

    example "get_init_msg returns positive values for stream counts" do
      init_msg = @socket.get_init_msg
      expect(init_msg.num_ostreams).to be >= 0
      expect(init_msg.max_instreams).to be >= 0
    end

    example "get_init_msg returns reasonable values for attempts and timeout" do
      init_msg = @socket.get_init_msg
      expect(init_msg.max_attempts).to be >= 0
      expect(init_msg.max_init_timeout).to be >= 0
    end

    example "get_init_msg does not accept any arguments" do
      expect{ @socket.get_init_msg(true) }.to raise_error(ArgumentError)
      expect{ @socket.get_init_msg({}) }.to raise_error(ArgumentError)
      expect{ @socket.get_init_msg(1, 2) }.to raise_error(ArgumentError)
    end

    example "get_init_msg returns consistent values on multiple calls" do
      init_msg1 = @socket.get_init_msg
      init_msg2 = @socket.get_init_msg
      expect(init_msg1.num_ostreams).to eq(init_msg2.num_ostreams)
      expect(init_msg1.max_instreams).to eq(init_msg2.max_instreams)
      expect(init_msg1.max_attempts).to eq(init_msg2.max_attempts)
      expect(init_msg1.max_init_timeout).to eq(init_msg2.max_init_timeout)
    end

    example "get_initmsg is an alias for get_init_msg" do
      expect(@socket.method(:get_initmsg)).to eq(@socket.method(:get_init_msg))
    end
  end
end
