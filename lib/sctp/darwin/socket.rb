require_relative 'constants'
require_relative 'structs'
require_relative 'functions'
require 'socket'

class SCTPSocket
  include SCTP::Constants
  include SCTP::Functions
  extend SCTP::Structs
  extend SCTP::Functions

  attr_reader :port

  # Create a new SCTP socket using UDP port.
  #
  # Possible options are:
  #
  #   :domain    - default is Socket::PF_INET.
  #   :type      - default is Socket::SOCK_SEQPACKET.
  #   :port      - default is 9899.
  #   :send      - callback function executed on send, default is nil.
  #   :receive   - callback function executed on receive, default is nil.
  #   :threshold - amount of free space in buffer before send, default is zero.
  #
  def initialize(**options)
    @domain    = options[:domain]    || options[:family] || Socket::PF_INET
    @type      = options[:type]      || Socket::SOCK_SEQPACKET
    @port      = options[:port]      || 9899
    @send      = options[:send]      || options[:send_callback]
    @receive   = options[:receive]   || options[:receive_callback]
    @threshold = options[:threshold] || 0

    @protocol = IPPROTO_SCTP

    unless [Socket::PF_INET, Socket::PF_INET6].include?(@domain)
      raise ArgumentError, "invalid domain: #{@domain}"
    end

    unless [Socket::SOCK_SEQPACKET, Socket::SOCK_STREAM].include?(@type)
      raise ArgumentError, "invalid socket type: #{@type}"
    end

    usrsctp_init(@port, nil, nil)

    # Not sure what last param is actually for, set it to nil for now
    @socket = usrsctp_socket(@domain, @type, @protocol, @receive, @send, @threshold, nil)

    if @socket.nil? || @socket.null?
      raise SystemCallError.new('usrsctp_socket', FFI.errno)
    end
  end

  def bind
    inaddr = SCTPSocket::InAddr.new
    inaddr[:s_addr] = Socket::INADDR_ANY

    addr = SCTPSocket::SockAddrIn.new
    addr[:sin_len]    = addr.size
    addr[:sin_family] = Socket::AF_INET
    addr[:sin_addr]   = inaddr
    addr[:sin_port]   = SCTPSocket.c_htons(@port)

    if usrsctp_bind(@socket, addr, addr.size) < 0
      raise SystemCallError.new('usrsctp_bind', FFI.errno)
    end
  end

  def close
    usrsctp_close(@socket) if @socket
    usrsctp_finish
  end

  # Connect to a remote SCTP address
  def connect(remote_addr, remote_port)
    inaddr = SCTPSocket::InAddr.new
    inaddr[:s_addr] = IPAddr.new(remote_addr).to_i

    addr = SCTPSocket::SockAddrIn.new
    addr[:sin_len]    = addr.size
    addr[:sin_family] = Socket::AF_INET
    addr[:sin_addr]   = inaddr
    addr[:sin_port]   = SCTPSocket.c_htons(remote_port)

    if usrsctp_connect(@socket, addr, addr.size) < 0
      raise SystemCallError.new('usrsctp_connect', FFI.errno)
    end
    true
  end

  # Send data over SCTP
  def send(data, stream: 0, ppid: 0)
    buf = FFI::MemoryPointer.from_string(data)
    flags = 0
    if usrsctp_sendv(@socket, buf, buf.size, nil, 0, nil, 0, SCTP_SENDV_NOINFO, ppid, flags) < 0
      raise SystemCallError.new('usrsctp_sendv', FFI.errno)
    end
    true
  end

  # Set SCTP socket option
  def set_sockopt(level, optname, optval)
    optval_ptr = FFI::MemoryPointer.new(optval.class, 1)
    optval_ptr.write(optval)
    if usrsctp_setsockopt(@socket, level, optname, optval_ptr, optval_ptr.size) < 0
      raise SystemCallError.new('usrsctp_setsockopt', FFI.errno)
    end
    true
  end

  # Get SCTP socket option
  def get_sockopt(level, optname, optlen)
    optval_ptr = FFI::MemoryPointer.new(:char, optlen)
    if usrsctp_getsockopt(@socket, level, optname, optval_ptr, FFI::MemoryPointer.new(:int, 1).write_int(optlen)) < 0
      raise SystemCallError.new('usrsctp_getsockopt', FFI.errno)
    end
    optval_ptr.read_bytes(optlen)
  end

  # Subscribe to SCTP events
  def subscribe_events(event_mask)
    # event_mask should be a hash of event => true/false
    events = SCTP::Structs::SctpEventSubscribe.new
    event_mask.each do |event, enabled|
      events[event] = enabled ? 1 : 0
    end
    set_sockopt(IPPROTO_SCTP, SCTP_EVENT, events)
  end
end

if $0 == __FILE__
  begin
    receive_cb = Proc.new do |socket, _sockstore, data, datalen, _recvinfo, flags|
      usrsctp_close(socket) if data.nil? || data.null?
      puts "DATA: #{data}"
    end

    port = 7

    inaddr = SCTPSocket::InAddr.new
    inaddr[:s_addr] = Socket::INADDR_ANY

    addr = SCTPSocket::SockAddrIn.new
    addr[:sin_len]    = addr.size
    addr[:sin_family] = Socket::AF_INET
    addr[:sin_addr]   = inaddr
    addr[:sin_port]   = SCTPSocket.c_htons(port)

    socket = SCTPSocket.new(port: 11111, threshold: 128, receive: receive_cb)

    if SCTPSocket.usrsctp_bind(socket, addr, addr.size) < 0
      raise SystemCallError.new('usrsctp_bind', FFI.errno)
    end
  ensure
    socket.close if socket
  end
end
