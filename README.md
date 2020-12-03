## Description

A Ruby interface for SCTP sockets.

WARNING: THIS IS CURRENTLY AN ALPHA PRODUCT. NOT RECOMMENDED FOR PRODUCTION USE AT THIS TIME.

## Prerequisites

You will need the sctp development headers installed.

On some systems, such as RHEL8, you may need to enable the sctp module.

## Installation

  `gem install sctp-socket`

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

```
# sample_server.rb
require 'sctp/socket'

begin
  port = 62324
  socket = SCTP::Socket.new
  socket.bind(:port => port, :addresses => ['10.0.5.4', '10.0.6.4'])
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

## Future Plans

* Add more constants.
* Add more specs.
* Add more notifications.

## Known Issues

Currently this has only been developed and tested on Linux. Other platforms
will probably only be supported via community contributions.

Please report any issues on the github project page.

  https://github.com/djberg96/sctp-socket

## More Information on SCTP

* https://www.linuxjournal.com/article/9784

## License

Apache-2.0

## Copyright

(C) 2020, Daniel J. Berger
Al Rights Reserved

## Author

Daniel J. Berger
djberg96 at gmail dot com
