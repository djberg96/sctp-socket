require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "get_retransmission_info" do
    before do
      @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
      @server.listen
      @socket.connectx(:addresses => addresses, :port => port, :reuse_addr => true)
    end

    example "get_retransmission_info returns expected value" do
      info = @server.get_retransmission_info
      expect(info.association_id).to be_a(Integer)
      expect(info.min).to be_a(Integer)
      expect(info.max).to be_a(Integer)
      expect(info.initial).to be_a(Integer)
    end

    example "get_retransmission_info does not accept any arguments" do
      expect{ @server.get_retransmission_info(true) }.to raise_error(ArgumentError)
    end

    example "get_rto_info is an alias for get_retransmission_info" do
      expect(@server.method(:get_rto_info)).to eq(@server.method(:get_retransmission_info))
    end
  end

  context "get_association_info" do
    before do
      @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
      @server.listen
      @socket.connectx(:addresses => addresses, :port => port, :reuse_addr => true)
    end

    example "get_association_info returns expected value" do
      info = @server.get_association_info
      expect(info.association_id).to be_a(Integer)
      expect(info.max_retransmission_count).to be_a(Integer)
      expect(info.number_peer_destinations).to be_a(Integer)
      expect(info.peer_receive_window).to be_a(Integer)
      expect(info.local_receive_window).to be_a(Integer)
      expect(info.cookie_life).to be_a(Integer)
    end

    example "get_association_info does not accept any arguments" do
      expect{ @server.get_association_info(true) }.to raise_error(ArgumentError)
    end
  end
end
