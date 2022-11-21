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

    usrsctp_init(@port)

    # Not sure what last param is actually for, set it to nil for now
    @socket = usrsctp_socket(@domain, @type, @protocol, @receive, @send, @threshold, nil)

    if @socket.nil? || @socket.null?
      raise SystemCallError.new('usrsctp_socket', FFI.errno)
    end
  end

  def close
    usrsctp_close(@socket) if @socket
    usrsctp_finish
  end
end

if $0 == __FILE__
  begin
    receive_cb = Proc.new do |socket, _sockstore, data, datalen, _recvinfo, flags|
      usrsctp_close(socket) if data.nil? || data.null?
      puts "DATA: #{data}"
    end

    socket = SCTPSocket.new(port: 11111, threshold: 128, receive: receive_cb)
  ensure
    socket.close if socket
  end
end
