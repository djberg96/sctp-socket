require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "getpeernames" do
    before do
      @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
      @server.listen
    end

    example "getpeernames returns the expected array" do
      @socket.connectx(:addresses => addresses, :port => port)
      expect(@socket.getpeernames).to eq(addresses)
    end
  end
end
