require 'sctp/socket'

RSpec.describe SCTP::Socket do
  context "basic" do
    example "basic" do
      expect(described_class).to be(described_class)
    end
  end
end
