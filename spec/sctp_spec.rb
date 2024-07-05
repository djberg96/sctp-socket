require 'rspec'
require 'sctp/socket'
require 'mkmf/lite'

RSpec.describe SCTPSocket do
  include Mkmf::Lite

  if have_header('usrsctp.h', '/usr/local/include')
    let(:sctp_header){ 'usrsctp.h' }
  else
    let(:sctp_header){ 'netinet/sctp.h' }
  end

  ENV['CPATH'] ||= '/usr/local/include'

  before do
    if RbConfig::CONFIG['host_os'] =~ /bsd|dragonfly/i
      @sockaddr_header = "sys/socket.h"
      @sockaddr_in_header = "netinet/in.h"
    else
      @sockaddr_header = "arpa/inet.h"
      @sockaddr_in_header = "arpa/inet.h"
    end
  end

  context "structs" do
    example "SCTP::Struct::Sockaddr is the expected size" do
      expect(check_sizeof("struct sockaddr", @sockaddr_header)).to eq(SCTP::Structs::Sockaddr.size)
    end

    example "SCTP::Struct::SockAddrIn is the expected size" do
      expect(check_sizeof("struct sockaddr_in", @sockaddr_in_header)).to eq(SCTP::Structs::SockAddrIn.size)
    end

    example "SCTP::Struct::InAddr is the expected size" do
      expect(check_sizeof("struct in_addr", @sockaddr_in_header)).to eq(SCTP::Structs::InAddr.size)
    end
  end

  context "C functions" do
    include SCTP::Functions

    example "htons returns the expected value" do
      expect(c_htons(42000)).to eq(4260)
    end

    example "inet_addr returns the expected value" do
      expect(c_inet_addr('127.0.0.1')).to eq(16777343)
    end
  end

  context "constants" do
    include SCTP::Constants

    example "SCTP_BINDX_ADD_ADDR is set to the expected value" do
      expect(check_valueof("SCTP_BINDX_ADD_ADDR", sctp_header)).to eq(SCTP::Constants::SCTP_BINDX_ADD_ADDR)
    end
  end
end
