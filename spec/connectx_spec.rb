require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "connectx" do
    before do
      @server.bindx(:port => port, :reuse_addr => true)
      @server.listen
    end

    example "connectx basic check" do
      expect{ @socket.connectx(:addresses => addresses, :port => port) }.not_to raise_error
    end

    example "association ID is set after connectx" do
      @socket.connectx(:addresses => addresses, :port => port)
      expect(@socket.association_id).to be > 0
    end

    example "connectx requires both a port and an array of addresses" do
      expect{ @socket.connectx }.to raise_error(ArgumentError)
      expect{ @socket.connectx(:port => port) }.to raise_error(ArgumentError)
      expect{ @socket.connectx(:addresses => addresses) }.to raise_error(ArgumentError)
    end
  end
end
