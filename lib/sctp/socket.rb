require_relative 'constants'
require_relative 'structs'
require_relative 'functions'
require 'socket'

class SCTPSocket
  include SCTP::Constants
  include SCTP::Functions
  extend SCTP::Structs
  extend SCTP::Functions

  attr_reader :domain
  attr_reader :type
  attr_reader :sock_fd

  def initialize(domain: Socket::AF_INET, type: Socket::SOCK_SEQPACKET)
    @domain = domain
    @type = type
    @sock_fd = socket(domain, type, IPPROTO_SCTP)

    if @sock_fd < 0
      raise SystemCallError.new('socket', FFI.errno)
    end
  end

  def bindx(addresses:, port:)
    if sctp_bindx(sock_fd, sockaddrs, sockaddrs.size, SCTP_BINDX_ADD_ADDR) < 0
      raise SystemCallError.new('bindx', FFI.errno)
    end
    self
  end

  def closex
    if close(sock_fd) < 0
      raise SystemCallError.new('bindx', FFI.errno)
    end
  end
end

if $0 == __FILE__
  socket = SCTPSocket.new

  addr1 = SCTP::Structs::SockAddrIn.new
  addr2 = SCTP::Structs::SockAddrIn.new

  socket.bindx(addresses: [addr1, addr2], port: 3000)
  socket.closex
end
