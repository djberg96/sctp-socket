require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "get_status" do
    before do
      @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
      @server.listen
      @socket.connectx(:addresses => addresses, :port => port, :reuse_addr => true)
    end

    example "get_status return the expected struct" do
      expect(@socket.get_status).to be_a(Struct::Status)
    end

    example "status struct contains expected values" do
      struct = @socket.get_status
      expect(struct.association_id).to be_a(Integer)
      expect(struct.state).to be_a(Integer)
      expect(struct.receive_window).to be_a(Integer)
      expect(struct.unacknowledged_data).to be_a(Integer)
      expect(struct.pending_data).to be_a(Integer)
      expect(struct.inbound_streams).to be_a(Integer)
      expect(struct.outbound_streams).to be_a(Integer)
      expect(struct.fragmentation_point).to be_a(Integer)
      expect(struct.primary).to eq(addresses.first)
    end
  end
end
