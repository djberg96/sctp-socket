require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  # For the purposes of these specs we're setting reuse_addr to true just
  # to avoid address-in-use errors, as we don't care about data loss.
  #
  context "bindx" do
    example "bindx both sets and returns port value" do
      port = @server.bindx(:reuse_addr => true)
      expect(@server.port).to eq(port)
    end

    example "bindx with no arguments" do
      expect{ @server.bindx(:reuse_addr => true) }.not_to raise_error
    end

    example "bindx with addresses" do
      expect{ @server.bindx(:addresses => addresses, :reuse_addr => true) }.not_to raise_error
    end

    example "bindx with explicit port value" do
      expect{ @server.bindx(:port => port, :reuse_addr => true) }.not_to raise_error
      expect(@server.port).to eq(port)
    end

    example "bindx using explicit flags to add addresses" do
      expect{
        @server.bindx(
          :addresses => addresses,
          :flags => SCTP::Socket::SCTP_BINDX_ADD_ADDR,
          :reuse_addr => true
        )
      }.not_to raise_error
    end

    example "bindx using explicit flags to remove addresses" do
      @server.bindx(:port => port, :addresses => addresses)
      expect{
        @server.bindx(
          :port => port,
          :addresses => [addresses.last],
          :flags => SCTP::Socket::SCTP_BINDX_REM_ADDR,
          :reuse_addr => true
        )
      }.not_to raise_error
    end
  end
end
