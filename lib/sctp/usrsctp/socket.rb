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

    ObjectSpace.define_finalizer(@socket, proc{ finish })
  end

  def accept(**options)
    addresses = options.fetch(:addresses)
    port = options[:port] || 0

    addrs = FFI::MemoryPointer.new(SockAddrIn, addresses.size)

    addresses.each_with_index do |address, i|
      struct = SockAddrIn.new
      struct[:sin_len] = struct.size if struct.members.include?(:sin_len)
      struct[:sin_family] = @domain
      struct[:sin_port] = c_htons(port)
      struct[:sin_addr][:s_addr] = c_inet_addr(address)
      addrs[i].write_pointer(struct)
    end

    if usrsctp_accept(@socket, addrs, addrs.size) < 0
      raise SystemCallError.new('usrsctp_accept', FFI.errno)
    end

    port
  end

  def bind(address = Socket::INADDR_ANY)
    addr = SockAddrIn.new
    addr[:sin_len] = addr.size if addr.members.include?(:sin_len)
    addr[:sin_family] = @domain
    addr[:sin_port] = c_htons(port)
    addr[:sin_addr][:s_addr] = c_htonl(address)

    if usrsctp_bind(@socket, addr, addr.size) < 0
      raise SystemCallError.new('usrsctp_bind', FFI.errno)
    end

    address
  end

  def bindx(**options)
    addresses = options.fetch(:addresses)
    flags = options[:flags] || SCTP_BINDX_ADD_ADDR
    port  = options[:port] || 0

    addrs = FFI::MemoryPointer.new(SockAddrIn, addresses.size)

    addresses.each_with_index do |address, i|
      struct = SockAddrIn.new
      struct[:sin_len] = struct.size if struct.members.include?(:sin_len)
      struct[:sin_family] = @domain
      struct[:sin_port] = c_htons(port)
      struct[:sin_addr][:s_addr] = c_inet_addr(address)
      addrs[i].write_pointer(struct)
    end

    if usrsctp_bindx(@socket, addrs, addrs.size, flags) < 0
      raise SystemCallError.new('usrsctp_bindx', FFI.errno)
    end

    port
  end

  def listen(backlog = 128)
    if usrsctp_listen(@socket, backlog) < 0
      raise SystemCallError.new('usrsctp_listen', FFI.errno)
    end
  end

  def connect(address = Socket::INADDR_ANY)
    addr = SockAddrIn.new
    addr[:sin_len] = addr.size if addr.members.include?(:sin_len)
    addr[:sin_family] = @domain
    addr[:sin_port] = c_htons(port)
    addr[:sin_addr][:s_addr] = c_htonl(address)

    if usrsctp_connect(@socket, addr, addr.size) < 0
      raise SystemCallError.new('usrsctp_connect', FFI.errno)
    end

    address
  end

  def connectx(**options)
    addresses = options.fetch(:addresses)
    flags = options[:flags] || 0
    association_id = options[:association_id]

    addrs = FFI::MemoryPointer.new(SockAddrIn, addresses.size)

    addresses.each_with_index do |address, i|
      struct = SockAddrIn.new
      struct[:sin_len] = struct.size if struct.members.include?(:sin_len)
      struct[:sin_family] = @domain
      struct[:sin_port] = c_htons(port)
      struct[:sin_addr][:s_addr] = c_inet_addr(address)
      addrs[i].write_pointer(struct)
    end

    if usrsctp_connectx(@socket, addrs, addrs.size, association_id) < 0
      raise SystemCallError.new('usrsctp_connectx', FFI.errno)
    end

    association_id
  end

  # Close the socket.
  #
  def close
    usrsctp_close(@socket) if @socket
  end

  # Frees all the memory that was allocated before. This should be the very last
  # call. You will typically only want to call this in a finalizer, if at all.
  #
  def finish
    if usrsctp_finish < 0
      raise SystemCallError.new('usrsctp_finish', FFI.errno)
    end
  end

  # Shuts down the read and/or write operations. The +how+ specifies the nature
  # of the shutdown. There are three possible values:
  #
  # * SHUT_RD - Disables further receives, but no protocol action is taken.
  # * SHUT_WR - Disables further sends, and initiates the shutdown sequence
  # * SHUT_RDWR - Disables further sends and receives, and initiates the shutdown sequence.
  #
  def shutdown(how = SHUT_RDWR)
    if usrsctp_shutdown(@socket, how) < 0
      raise SystemCallError.new('usrsctp_shutdown', FFI.errno)
    end
  end

  def sysctl_get(method_name)
    send("usrsctp_sysctl_get_sctp_#{method_name}".to_sym)
  end

  def sysctl_set(method_name, value)
    send("usrsctp_sysctl_set_sctp_#{method_name}".to_sym, value)
  end
end

if $0 == __FILE__
  begin
    receive_cb = Proc.new do |socket, _sockstore, data, datalen, _recvinfo, flags|
      usrsctp_close(socket) if data.nil? || data.null?
      puts "DATA: #{data}"
    end

    addresses = ['1.1.1.1', '1.1.1.2']

    socket = SCTPSocket.new
    #socket.bind
    p socket.sysctl_get(:rto_min_default)
    p socket.sysctl_get(:rto_max_default)
    #socket.bindx(:addresses => addresses)
    #socket = SCTPSocket.new(port: 11111, threshold: 128, receive: receive_cb)
    #socket = SCTPSocket.new(port: 11111, threshold: 128, receive: receive_cb)
  ensure
    socket.close if socket
    #socket.finish
  end
end
