require_relative 'constants'
require_relative 'structs'
require_relative 'functions'
require 'socket'

class SCTPSocket
  include SCTP::Constants
  extend SCTP::Structs
  extend SCTP::Functions

  attr_reader :domain
  attr_reader :type
  attr_reader :sock_fd

  def initialize(domain: Socket::AF_INET, type: Socket::SOCK_SEQPACKET)
    @domain = domain
    @type = type
    @sock_fd = socket(domain, type, Socket::IPPROTO_SCTP)
  end

  def bindx(sockaddrs)
    if sctp_bindx(sock_fd, sockaddrs, sockaddrs.size, SCTP_BINDX_ADD_ADDR) < 0
      raise SystemCallError.new('bindx', FFI.errno)
    end
    self
  end
end
