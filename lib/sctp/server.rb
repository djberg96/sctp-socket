require 'socket'
require 'sctp/socket'

module SCTP
  # SCTP::Server provides a TCPServer-like interface for SCTP sockets.
  #
  # Unlike TCP which uses accept() to create new sockets for each connection,
  # SCTP can operate in one-to-many mode where a single socket handles
  # multiple associations. This server class provides both modes:
  #
  # 1. One-to-many mode (default): All connections share the server socket
  # 2. One-to-one mode: Uses peeloff() to create individual sockets per association
  #
  # Example usage:
  #
  #   # Basic one-to-many server
  #   server = SCTP::Server.new(['127.0.0.1'], 9999)
  #   loop do
  #     data, info = server.recvmsg
  #     puts "Received: #{data} from association #{info.association_id}"
  #     server.sendmsg("Echo: #{data}", association_id: info.association_id)
  #   end
  #
  #   # One-to-one server with peeloff
  #   server = SCTP::Server.new(['127.0.0.1'], 9999, one_to_one: true)
  #   loop do
  #     client = server.accept  # Returns a new SCTP::Socket for the association
  #     Thread.new(client) do |c|
  #       data, info = c.recvmsg
  #       c.sendmsg("Echo: #{data}")
  #       c.close
  #     end
  #   end
  #
  class Server
    attr_reader :socket, :addresses, :port, :one_to_one

    # Create a new SCTP server.
    #
    # @param addresses [Array<String>, String, nil] IP addresses to bind to.
    #   If nil, binds to all available addresses.
    # @param port [Integer] Port number to bind to
    # @param one_to_one [Boolean] If true, uses one-to-one mode with peeloff.
    #   If false (default), uses one-to-many mode.
    # @param backlog [Integer] Listen backlog (default: 128)
    # @param socket_options [Hash] Additional socket options
    def initialize(addresses = nil, port = 0, one_to_one: false, backlog: 128, **socket_options)
      @addresses = Array(addresses) if addresses
      @port = port
      @one_to_one = one_to_one
      @backlog = backlog
      @socket_options = socket_options
      @pending_associations = {}

      # Create the main server socket
      if one_to_one
        @socket = SCTP::Socket.new(2, 1)  # AF_INET, SOCK_STREAM
      else
        @socket = SCTP::Socket.new(2, 5)  # AF_INET, SOCK_SEQPACKET
      end

      setup_socket
      bind_and_listen
    end

    # Accept a new association (one-to-one mode only).
    #
    # In one-to-many mode, this method is not used. Instead, use recvmsg
    # to receive data from any association.
    #
    # @return [SCTP::Socket] A new socket for the accepted association
    # @raise [RuntimeError] If not in one-to-one mode
    def accept
      raise "accept() only available in one-to-one mode" unless @one_to_one

      # Wait for a message to establish an association
      data, info = @socket.recvmsg
      association_id = info.association_id

      # Check if we already have a peeled-off socket for this association
      if @pending_associations[association_id]
        client_socket = @pending_associations.delete(association_id)
      else
        # Peeloff a new socket for this association
        client_socket = @socket.peeloff(association_id)
      end

      # Store the initial message in the client socket for retrieval
      client_socket.instance_variable_set(:@initial_message, [data, info])

      # Add a method to retrieve the initial message
      def client_socket.initial_message
        @initial_message
      end

      client_socket
    end

    # Receive a message from any association (one-to-many mode).
    #
    # @param flags [Integer] Receive flags (default: 0)
    # @return [Array<String, Struct>] Message data and info struct
    def recvmsg(flags = 0)
      @socket.recvmsg(flags)
    end

    # Send a message to a specific association (one-to-many mode).
    #
    # @param data [String] Data to send
    # @param options [Hash] Send options including :association_id
    # @return [Integer] Number of bytes sent
    def sendmsg(data, **options)
      @socket.sendmsg(options.merge(message: data))
    end

    # Get local addresses bound to this server.
    #
    # @return [Array<String>] Local addresses
    def addr
      @socket.getlocalnames
    end

    # Get the local port number.
    #
    # @return [Integer] Port number
    def local_port
      @socket.port
    end

    # Check if the server is closed.
    #
    # @return [Boolean] true if closed, false otherwise
    def closed?
      @socket.closed?
    end

    # Close the server socket.
    #
    # @param options [Hash] Close options (e.g., linger: seconds)
    def close(**options)
      @socket.close(options) unless closed?
    end

    # Get server socket information.
    #
    # @return [String] String representation of the server
    def to_s
      if closed?
        "#<SCTP::Server:closed>"
      else
        mode = @one_to_one ? "one-to-one" : "one-to-many"
        "#<SCTP::Server:#{addr.join(',')}:#{local_port} (#{mode})>"
      end
    end

    alias_method :inspect, :to_s

    private

    def setup_socket
      # Apply any socket options provided
      @socket_options.each do |option, value|
        case option
        when :reuse_addr
          # SCTP typically doesn't need SO_REUSEADDR like TCP
          # but we can support it for compatibility
        when :autoclose
          @socket.autoclose = value
        when :nodelay
          @socket.nodelay = value
        when :init_msg
          @socket.set_initmsg(value)
        when :subscriptions
          @socket.subscribe(value)
        else
          # For any other options, try to call them as methods
          if @socket.respond_to?("#{option}=")
            @socket.send("#{option}=", value)
          end
        end
      end

      # Set up default subscriptions for server operation
      @socket.subscribe(
        data_io: true,
        association: true,
        address: true,
        send_failure: true,
        shutdown: true
      )
    end

    def bind_and_listen
      if @addresses && !@addresses.empty?
        @socket.bindx(port: @port, addresses: @addresses, reuse_addr: true)
      else
        # Bind to all available addresses
        @socket.bindx(port: @port, reuse_addr: true)
      end

      @socket.listen(@backlog)

      # Update port if it was auto-assigned (port 0)
      @port = @socket.port if @port == 0
    end
  end
end
