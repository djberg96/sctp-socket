require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "getlocalnames" do
    before do
      @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
      @server.listen
    end

    # TODO: FreeBSD is picking up localhost and em0 here, is that normal?
    example "getlocalnames returns the expected array" do
      @socket.connectx(:addresses => addresses, :port => port)
      expect(@socket.getlocalnames).to include(*addresses)
    end
  end
end
