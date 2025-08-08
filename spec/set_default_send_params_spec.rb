require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "set_default_send_params" do
    example "set_default_send_params basic functionality" do
      expect(@socket).to respond_to(:set_default_send_params)
    end

    example "set_default_send_params requires a hash argument" do
      expect{ @socket.set_default_send_params("invalid") }.to raise_error(TypeError)
      expect{ @socket.set_default_send_params(123) }.to raise_error(TypeError)
      expect{ @socket.set_default_send_params(nil) }.to raise_error(TypeError)
    end

    example "set_default_send_params accepts an empty hash" do
      expect{ @socket.set_default_send_params({}) }.not_to raise_error
    end

    example "set_default_send_params accepts stream parameter" do
      options = { stream: 1 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts ssn parameter" do
      options = { ssn: 100 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts flags parameter" do
      options = { flags: 1 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts ppid parameter" do
      options = { ppid: 12345 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts context parameter" do
      options = { context: 999 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts ttl parameter" do
      options = { ttl: 5000 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts tsn parameter" do
      options = { tsn: 54321 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts cumtsn parameter" do
      options = { cumtsn: 67890 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts association_id parameter" do
      options = { association_id: 0 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts multiple parameters" do
      options = {
        stream: 2,
        flags: 1,
        ppid: 12345,
        context: 999,
        ttl: 5000
      }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params returns a DefaultSendParams struct" do
      options = { stream: 1, ppid: 12345 }
      result = @socket.set_default_send_params(options)
      expect(result).to be_a(Struct)
      expect(result.class.name).to match(/DefaultSendParams/)
    end

    example "set_default_send_params accepts string keys" do
      options = { "stream" => 1, "ppid" => 12345 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params accepts symbol keys" do
      options = { :stream => 1, :ppid => 12345 }
      expect{ @socket.set_default_send_params(options) }.not_to raise_error
    end

    example "set_default_send_params with all numeric parameters" do
      options = {
        stream: 3,
        ssn: 200,
        flags: 2,
        ppid: 54321,
        context: 1234,
        ttl: 10000,
        tsn: 98765,
        cumtsn: 13579,
        association_id: 0
      }
      result = @socket.set_default_send_params(options)
      expect(result).to be_a(Struct)
    end

    example "set_default_send_params with SCTP constant flags" do
      # Test with SCTP_UNORDERED flag if available
      begin
        flags = described_class::SCTP_UNORDERED
        options = { stream: 1, flags: flags }
        expect{ @socket.set_default_send_params(options) }.not_to raise_error
      rescue NameError
        # Constant not available, skip this part
        options = { stream: 1, flags: 1 }
        expect{ @socket.set_default_send_params(options) }.not_to raise_error
      end
    end
  end
end
