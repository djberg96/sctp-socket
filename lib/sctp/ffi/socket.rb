require 'socket'
require_relative 'constants'
require_relative 'structs'
require_relative 'functions'

module SCTP
  class Socket < ::Socket
    include SCTP::Constants
    include SCTP::Functions
    extend SCTP::Structs
    extend SCTP::Functions

    attr_reader :port, :socket

    def initialize(domain: ::Socket::PF_INET, type: ::Socket::SOCK_SEQPACKET, port: 9899, send_callback: nil, receive_callback: nil, threshold: 0)
      @domain = domain
      @type = type
      @port = port
      @send_callback = send_callback
      @receive_callback = receive_callback
      @threshold = threshold
      @protocol = IPPROTO_SCTP

      SCTP::Functions.usrsctp_init(@port, nil, nil)
      @socket = SCTP::Functions.usrsctp_socket(@domain, @type, @protocol, @receive_callback, @send_callback, @threshold, nil)
      raise SystemCallError.new('usrsctp_socket', FFI.errno) if @socket.nil? || @socket.null?
    end

    def bind
      inaddr = SCTP::Structs::InAddr.new
      inaddr[:s_addr] = ::Socket::INADDR_ANY
      addr = SCTP::Structs::SockAddrIn.new
      addr[:sin_len] = addr.size
      addr[:sin_family] = ::Socket::AF_INET
      addr[:sin_addr] = inaddr
      addr[:sin_port] = [@port].pack('n').unpack1('S>')
      if SCTP::Functions.usrsctp_bind(@socket, addr, addr.size) < 0
        raise SystemCallError.new('usrsctp_bind', FFI.errno)
      end
    end

    def connect(remote_addr, remote_port)
      inaddr = SCTP::Structs::InAddr.new
      inaddr[:s_addr] = IPAddr.new(remote_addr).to_i
      addr = SCTP::Structs::SockAddrIn.new
      addr[:sin_len] = addr.size
      addr[:sin_family] = ::Socket::AF_INET
      addr[:sin_addr] = inaddr
      addr[:sin_port] = [remote_port].pack('n').unpack1('S>')
      if SCTP::Functions.usrsctp_connect(@socket, addr, addr.size) < 0
        raise SystemCallError.new('usrsctp_connect', FFI.errno)
      end
      true
    end

    def send(data, stream: 0, ppid: 0)
      buf = FFI::MemoryPointer.from_string(data)
      flags = 0
      if SCTP::Functions.usrsctp_sendv(@socket, buf, buf.size, nil, 0, nil, 0, SCTP_SENDV_NOINFO, ppid, flags) < 0
        raise SystemCallError.new('usrsctp_sendv', FFI.errno)
      end
      true
    end

    def close
      SCTP::Functions.usrsctp_close(@socket) if @socket
      SCTP::Functions.usrsctp_finish
    end

    # ...add more methods as needed...
  end
end
