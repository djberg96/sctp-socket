require 'ffi'

module SCTP
  module Structs
    extend FFI::Library

    typedef :uint32_t, :sctp_assoc_t

    class SockaddrStorage < FFI::Struct
      layout(
        :ss_family, :sa_family_t,
        :ss_data, [:uint8_t, 26] # SOCKADDR_MAX_DATA_LEN
      )
    end

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
        :recvv_nxtinfo, SctpNxtinfo
      )
    end

    class SctpSndAllCompletes < FFI::Struct
      layout(
        :sall_stream, :uint16_t,
        :sall_flags, :uint16_t,
        :sall_ppid, :uint32_t,
        :sall_context, :uint32_t,
        :sall_num_sent, :uint32_t,
        :sall_num_failed, :uint32_t
      )
    end

    class SctpSndinfo < FFI::Struct
      layout(
        :snd_sid, :uint16_t,
        :snd_flags, :uint16_t,
        :snd_ppid, :uint32_t,
        :snd_context, :uint32_t,
        :snd_assoc_id, :sctp_assoc_t
      )
    end

    class SctpPrinfo < FFI::Struct
      layout(
        :pr_policy, :uint16_t,
        :pr_value, :uint32_t,
      )
    end

    class SctpAuthinfo < FFI::Struct
      layout(
        :auth_keynumber, :uint16_t
      )
    end

    class SctpSendvSpa < FFI::Struct
      layout(
        :sendv_flags, :uint32_t,
        :sendv_sndinfo, SctpSndinfo,
        :sendv_priinfo, SctpPrinfo,
        :sendv_authinfo, SctpAuthinfo
      )
    end

    class SctpUdpencaps < FFI::Struct
      layout(
        :sue_address, SockaddrStorage,
        :sue_assoc_id, :uint32_t,
        :sue_port, :uint16_t
      )
    end

    class SctpAssocChange < FFI::Struct
      layout(
        :sac_type, :uint16_t,
        :sac_flags, :uint16_t,
        :sac_length, :uint16_t,
        :sac_state, :uint16_t,
        :sac_error, :uint16_t,
        :sac_outbound_streams, :uint16_t,
        :sac_inbound_streams, :uint16_t,
        :sac_assoc_id, :sctp_assoc_t,
        :sac_info, [:uint8_t, 0]
      )
    end
  end
end
