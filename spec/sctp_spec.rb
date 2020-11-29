require 'sctp/socket'

RSpec.describe SCTP::Socket do
  context "version" do
    example "version is set to the expected value" do
      expect(SCTP::Socket::VERSION).to eq('0.0.2')
    end
  end

  context "basic" do
    example "basic" do
      expect(described_class).to be(described_class)
    end
  end
end
