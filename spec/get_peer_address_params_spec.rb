require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  before do
    create_connection
  end

  context "get_peer_address_params" do
    example "get_peer_address_params basic functionality" do
      expect(@server).to respond_to(:get_peer_address_params)
    end

    example "get_peer_address_params returns expected struct type" do
      params = @server.get_peer_address_params
      expect(params).to be_a(Struct)
      expect(params.class.name).to match(/PeerAddressParams/)
    end

    example "get_peer_address_params returns struct with expected members" do
      params = @server.get_peer_address_params
      expect(params).to respond_to(:association_id)
      expect(params).to respond_to(:address)
      expect(params).to respond_to(:heartbeat_interval)
      expect(params).to respond_to(:max_retransmission_count)
      expect(params).to respond_to(:path_mtu)
      expect(params).to respond_to(:flags)
      expect(params).to respond_to(:ipv6_flowlabel)
    end

    example "get_peer_address_params returns struct with expected value types" do
      params = @server.get_peer_address_params
      expect(params.association_id).to be_a(Integer)
      expect(params.address).to be_a(String)
      expect(params.heartbeat_interval).to be_a(Integer)
      expect(params.max_retransmission_count).to be_a(Integer)
      expect(params.path_mtu).to be_a(Integer)
      expect(params.flags).to be_a(Integer)
      expect(params.ipv6_flowlabel).to be_a(Integer)
    end

    example "get_peer_address_params address is a valid IP address" do
      params = @server.get_peer_address_params
      expect(params.address).to match(/\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\z/)
    end

    example "get_peer_address_params does not accept any arguments" do
      expect{ @server.get_peer_address_params(true) }.to raise_error(ArgumentError)
      expect{ @server.get_peer_address_params({}) }.to raise_error(ArgumentError)
      expect{ @server.get_peer_address_params(1, 2) }.to raise_error(ArgumentError)
    end

    example "get_peer_address_params returns consistent values on multiple calls" do
      params1 = @server.get_peer_address_params
      params2 = @server.get_peer_address_params
      expect(params1.association_id).to eq(params2.association_id)
      expect(params1.address).to eq(params2.address)
      expect(params1.flags).to eq(params2.flags)
    end
  end
end
