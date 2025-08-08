require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "set_peer_address_params" do
    example "set_peer_address_params basic functionality" do
      expect(@socket).to respond_to(:set_peer_address_params)
    end

    example "set_peer_address_params requires a hash argument" do
      expect{ @socket.set_peer_address_params("invalid") }.to raise_error(TypeError)
      expect{ @socket.set_peer_address_params(123) }.to raise_error(TypeError)
      expect{ @socket.set_peer_address_params(nil) }.to raise_error(TypeError)
    end

    example "set_peer_address_params accepts an empty hash" do
      expect{ @socket.set_peer_address_params({}) }.not_to raise_error
    end

    example "set_peer_address_params accepts hbinterval parameter" do
      options = { hbinterval: 5000 }
      expect{ @socket.set_peer_address_params(options) }.not_to raise_error
    end

    example "set_peer_address_params accepts pathmaxrxt parameter" do
      options = { pathmaxrxt: 5 }
      expect{ @socket.set_peer_address_params(options) }.not_to raise_error
    end

    example "set_peer_address_params accepts pathmtu parameter" do
      options = { pathmtu: 1500 }
      expect{ @socket.set_peer_address_params(options) }.not_to raise_error
    end

    example "set_peer_address_params accepts flags parameter" do
      options = { flags: 1 }
      expect{ @socket.set_peer_address_params(options) }.not_to raise_error
    end

    example "set_peer_address_params accepts association_id parameter" do
      options = { association_id: 0 }
      expect{ @socket.set_peer_address_params(options) }.not_to raise_error
    end

    example "set_peer_address_params accepts ipv6_flowlabel parameter" do
      options = { ipv6_flowlabel: 12345 }
      expect{ @socket.set_peer_address_params(options) }.not_to raise_error
    end

    example "set_peer_address_params accepts valid IPv4 address" do
      options = { address: "127.0.0.1" }
      # Note: This may fail with "Invalid argument" on disconnected socket
      # which is expected behavior - the test verifies the address parsing works
      begin
        @socket.set_peer_address_params(options)
      rescue SystemCallError => e
        # Expected for disconnected socket - just verify it's not an IP parsing error
        expect(e.message).to match(/setsockopt|Invalid argument/)
      end
    end

    example "set_peer_address_params rejects invalid IP address" do
      options = { address: "invalid.ip.address" }
      expect{ @socket.set_peer_address_params(options) }.to raise_error(ArgumentError)
    end

    example "set_peer_address_params accepts multiple parameters" do
      options = {
        hbinterval: 5000,
        pathmaxrxt: 5,
        pathmtu: 1500,
        flags: 1
      }
      expect{ @socket.set_peer_address_params(options) }.not_to raise_error
    end

    example "set_peer_address_params returns a PeerAddressParams struct" do
      options = { hbinterval: 5000 }
      result = @socket.set_peer_address_params(options)
      expect(result).to be_a(Struct)
      expect(result.class.name).to match(/PeerAddressParams/)
    end

    example "set_peer_address_params accepts string keys" do
      options = { "hbinterval" => 5000, "pathmaxrxt" => 5 }
      expect{ @socket.set_peer_address_params(options) }.not_to raise_error
    end

    example "set_peer_address_params accepts symbol keys" do
      options = { :hbinterval => 5000, :pathmaxrxt => 5 }
      expect{ @socket.set_peer_address_params(options) }.not_to raise_error
    end

    example "set_peer_address_params with numeric values" do
      options = {
        hbinterval: 1000,
        pathmaxrxt: 3,
        pathmtu: 1400,
        flags: 0,
        association_id: 0,
        ipv6_flowlabel: 0
      }
      result = @socket.set_peer_address_params(options)
      expect(result).to be_a(Struct)
    end
  end
end
