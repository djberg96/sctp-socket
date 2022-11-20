require 'ffi'

module SCTP
  module Structs
    extend FFI::Library

    typedef :uint32_t, :sctp_assoc_t

    class SctpCommonHeader < FFI::Struct
      layout(
        :source_port, :uint16_t,
        :destination_port, :uint16_t,
        :verification_tag, :uint16_t,
        :crc32c, :uint32_t
      )
    end

    class SockaddrConn < FFI::Struct
      layout(
        :sconn_len, :uint8_t,
        :sconn_family, :uint8_t,
        :sconn_port, :uint8_t,
        :sconn_addr, :pointer
      )
    end

    class SctpSockstore < FFI::Union
      layout(
        :sin, :pointer,
        :sin6, :pointer,
        :sconn, :pointer,
        :sa, :pointer
      )
    end

    class SctpRcvinfo < FFI::Struct
      layout(
        :rcv_sid, :uint16_t,
        :rcv_ssn, :uint16_t,
        :rcv_flags, :uint16_t,
        :rcv_ppid, :uint32_t,
        :rcv_tsn, :uint32_t,
        :rcv_cumtsn, :uint32_t,
        :rcv_context, :uint32_t,
        :rcv_assoc_id, :sctp_assoc_t
      )
    end

    class SctpNxtinfo < FFI::Struct
      layout(
        :nxt_sid, :uint16_t,
        :nxt_flags, :uint16_t,
        :nxt_ppid, :uint32_t,
        :nxt_length, :uint32_t,
        :nxt_assoc_id, :sctp_assoc_t
      )
    end

    class SctpRecvvRn < FFI::Struct
      layout(
        :recvv_rcvinfo, SctpRcvinfo,
        :recvv_nxtinfo, SctpNxtinfo,
      )
    end
  end
end
