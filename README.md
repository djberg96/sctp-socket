[![Ruby](https://github.com/djberg96/sctp-socket/actions/workflows/ruby.yml/badge.svg)](https://github.com/djberg96/sctp-socket/actions/workflows/ruby.yml)

## Description

A Ruby interface for SCTP sockets.

## Prerequisites

You will need the sctp development headers installed.

On some systems, such as RHEL8 or later, you may need to enable the sctp module.

## Installation

`gem install sctp-socket`

## Installing the Trusted Cert

`gem cert --add <(curl -Ls https://raw.githubusercontent.com/djberg96/sctp-socket/main/certs/djberg96_pub.pem)`

## About SCTP

The Stream Control Transmission Protocol (SCTP) is a message oriented, reliable
transport protocol with direct support for multihoming that runs on top of ip,
and supports both v4 and v6 versions.

Like TCP, SCTP provides reliable, connection oriented data delivery with
congestion control. Unlike TCP, SCTP also provides message boundary preservation,
ordered and unordered message delivery, multi-streaming and multi-homing.

Detection of data corruption, loss of data and duplication of data is achieved
by using checksums and sequence numbers. A selective retransmission mechanism
is applied to correct loss or corruption of data.

## Synopsis

```ruby
# sample_server.rb
require 'sctp/socket'

begin
  port = 62324
  socket = SCTP::Socket.new
  socket.bindx(:port => port, :addresses => ['10.0.5.4', '10.0.6.4'])
  socket.set_initmsg(:output_streams => 5, :input_streams => 5, :max_attempts => 4)
  socket.subscribe(:data_io => true)
  socket.listen

  while true
    data = socket.recvmsg
    puts data
  end
ensure
  socket.close
end
```

## Using SCTP::Server

The `SCTP::Server` class provides a TCPServer-like interface for SCTP sockets,
making it easier to create SCTP server applications.

### One-to-Many Mode (Default)

In one-to-many mode, a single server socket handles multiple client associations:

```ruby
require 'sctp/socket'

# Create server listening on multiple addresses
server = SCTP::Server.new(['127.0.0.1', '192.168.1.100'], 9999)

puts "Server listening on #{server.addr.join(', ')}:#{server.local_port}"

loop do
  # Receive data from any client association
  data, info = server.recvmsg
  puts "Received from association #{info.association_id}: #{data}"

  # Echo back to the same association
  server.sendmsg("Echo: #{data}", association_id: info.association_id)
end
```

### One-to-One Mode

In one-to-one mode, the server creates individual sockets for each association:

```ruby
require 'sctp/socket'

# Create server in one-to-one mode
server = SCTP::Server.new(['127.0.0.1'], 9999, one_to_one: true)

loop do
  # Accept a new client connection
  client = server.accept

  # Handle client in a thread
  Thread.new(client) do |c|
    # Get the initial message that established the connection
    data, info = c.initial_message
    puts "New client: #{data}"

    # Continue receiving from this specific client
    loop do
      data, info = c.recvmsg
      c.sendmsg("Echo: #{data}")
    end
  rescue => e
    puts "Client error: #{e.message}"
  ensure
    c.close
  end
end
```

### Server Options

```ruby
# Create server with additional options
server = SCTP::Server.new(
  ['127.0.0.1'],
  9999,
  one_to_one: false,
  backlog: 256,
  autoclose: 30,
  init_msg: { output_streams: 10, input_streams: 10 },
  subscriptions: { data_io: true, association: true }
)
```

## Future Plans

* Add more specs.
* Subclass the Socket class (but see known issues below).
* Create a wrapper for the usrlibsctp implementation using FFI.

## Known Issues

Currently this has only been developed and tested on Linux and BSD. Other
platforms will probably only be supported via community contributions.

The sendv and recvv methods may not be available. Use the sendmsg and recvmsg
methods instead if that's the case.

I am currently unable to subclass the Socket class from Ruby's standard library.
For whatever reason the call to rb_call_super works, but the fileno is always
set to nil. I think it's getting confused by the IPPROTO_SCTP value for the
protocol, but I haven't nailed it down yet.

Please report any issues on the github project page.

  https://github.com/djberg96/sctp-socket

## More Information on SCTP

* https://www.linuxjournal.com/article/9748
* https://www.linuxjournal.com/article/9749
* https://www.linuxjournal.com/article/9784
* SCTP in Theory and Practice - Svetomir Dimitrov
* Stream Control Transmission Protocol (A Reference Guide) - Randall Stewart and Qiaobing Xie

## License

Apache-2.0

## Copyright

(C) 2020-2026, Daniel J. Berger
Al Rights Reserved

## Author

Daniel J. Berger
djberg96 at gmail dot com
