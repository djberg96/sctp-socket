require_relative 'constants'
require_relative 'structs'
require_relative 'functions'
require 'socket'

class SCTPSocket
  include SCTP::Constants
  include SCTP::Functions
  extend SCTP::Structs
  extend SCTP::Functions

  attr_reader :family
  attr_reader :type
  attr_reader :sock_fd

  def initialize(family: Socket::AF_INET, type: Socket::SOCK_SEQPACKET)
    @family = family
    @type = type
    @sock_fd = c_socket(family, type, IPPROTO_SCTP)

    if @sock_fd < 0
      raise SystemCallError.new('socket', FFI.errno)
    end
  end

  def bind(address: 0, port: 0, family: Socket::AF_INET)
    sockaddr_in = SCTP::Structs::SockAddrIn.new
    sockaddr_in[:sin_family] = family
    sockaddr_in[:sin_port] = port
    sockaddr_in[:sin_addr][:s_addr] = c_inet_addr(address)

    if c_bind(sock_fd, sockaddr_in, SCTP::Structs::SockAddrIn.size) < 0
      raise SystemCallError.new('bind', FFI.errno)
    end

    self
  end

  def bindx(addresses: [], port: 0, family: Socket::AF_INET, flags: SCTP_BINDX_ADD_ADDR)
    addr = FFI::MemoryPointer.new(SCTP::Structs::SockAddrIn, addresses.size)

    sockaddrs = addresses.size.times.collect do |i|
      SCTP::Structs::SockAddrIn.new(addr + (i * SCTP::Structs::SockAddrIn.size))
    end

    if addresses.size > 0
      sockaddrs.each_with_index do |sock_addr, i|
        sock_addr[:sin_family] = family
        sock_addr[:sin_port] = c_htons(port)
        sock_addr[:sin_addr][:s_addr] = c_inet_addr(addresses[i])
      end
    else
      sockaddrs[0].sin_family = family
      sockaddrs[0].sin_port = c_htons(port)
      sockaddrs[0].sin_addr.s_addr = c_htonl(Socket::INADDR_ANY)
    end

    FFI::MemoryPointer.new(sockaddrs, sockaddrs.size) do |ptr|
      if sctp_bindx(sock_fd, ptr, ptr.size, flags) < 0
        raise SystemCallError.new('bindx', FFI.errno)
      end
    end

    self
  end

  def connectx(addresses: [], port: 0)
    addr = FFI::MemoryPointer.new(SCTP::Structs::SockAddrIn, addresses.size)

    sockaddrs = addresses.size.times.collect do |i|
      SCTP::Structs::SockAddrIn.new(addr + (i * SCTP::Structs::SockAddrIn.size))
    end

    sockaddrs.each_with_index do |sock_addr, i|
      sock_addr[:sin_family] = family
      sock_addr[:sin_port] = c_htons(port)
      sock_addr[:sin_addr][:s_addr] = c_inet_addr(addresses[i])
    end

    assoc_id = FFI::MemoryPointer.new(:int32)

    FFI::MemoryPointer.new(sockaddrs, sockaddrs.size) do |ptr|
      if sctp_connectx(sock_fd, ptr, ptr.size, assoc_id) < 0
        raise SystemCallError.new('connectx', FFI.errno)
      end
    end

    @association_id = assoc_id.read_int32

    self
  end

  def close
    if c_close(sock_fd) < 0
      raise SystemCallError.new('close', FFI.errno)
    end
  end
end

if $0 == __FILE__
  socket = SCTPSocket.new
  socket.connectx(port: 42000, addresses: ['127.0.0.1'])
  socket.close
end
