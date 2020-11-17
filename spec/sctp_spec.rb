require 'rspec'
require 'sctp/socket'
require 'mkmf/lite'

RSpec.describe SCTPSocket do
  context "structs" do
    include Mkmf::Lite

    example "SCTP::Struct::Sockaddr is the expected size" do
      expect(check_sizeof("struct sockaddr", "arpa/inet.h")).to eq(SCTP::Structs::Sockaddr.size)
    end

    example "SCTP::Struct::SockAddrIn is the expected size" do
      expect(check_sizeof("struct sockaddr_in", "arpa/inet.h")).to eq(SCTP::Structs::SockAddrIn.size)
    end

    example "SCTP::Struct::InAddr is the expected size" do
      expect(check_sizeof("struct in_addr", "arpa/inet.h")).to eq(SCTP::Structs::InAddr.size)
    end

  end
end
