require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  describe 'version' do
    example "version is set to the expected value" do
      expect(SCTP::Socket::VERSION).to eq('0.2.2')
    end
  end
end
