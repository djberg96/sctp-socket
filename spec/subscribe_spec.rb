require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "subscribe" do
    before do
      @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
      @server.listen
    end

    example "subscribe accepts a hash of options" do
      expect{ @server.subscribe(:data_io => true) }.not_to raise_error
      expect{ @server.subscribe(1) }.to raise_error(TypeError)
    end
  end

  context "get_subscriptions" do
    let(:subscriptions){ {:data_io => true, :shutdown => true} }

    before do
      @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
      @server.subscribe(subscriptions)
    end

    example "get_subscriptions returns expected values" do
      subscriptions = @server.get_subscriptions
      expect(subscriptions[:data_io]).to be true
      expect(subscriptions[:shutdown]).to be true
      expect(subscriptions[:association]).to be false
      expect(subscriptions[:authentication]).to be false
    end

    example "get_subscriptions does not accept any arguments" do
      expect{ @server.get_subscriptions(true) }.to raise_error(ArgumentError)
    end
  end
end
