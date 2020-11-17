require 'rspec'
require 'sctp/socket'
require 'mkmf/lite'

RSpec.describe SCTP::Socket do
  context "structs" do
    include Mkmf::Lite
    example "SCTP::Struct::SockAddrIn is the expected size" do
      expect(check_sizeof("struct sockaddr_in", "arpa/inet.h")).to eq(SCTP::Structs::SockAddrIn.size)
    end
  end
end
