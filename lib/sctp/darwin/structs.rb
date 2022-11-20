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

    class SctpRemoteError < FFI::Struct
      layout(
        :sre_type, :uint16_t,
        :sre_flags, :uint16_t,
        :sre_length, :uint32_t,
        :sre_error, :uint16_t,
        :sre_assoc_id, :sctp_assoc_t,
        :sre_data, [:uint8_t, 0]
      )
    end

    class SctpAdaptationEvent < FFI::Struct
      layout(
        :sai_type, :uint16_t,
        :sai_flags, :uint16_t,
        :sai_length, :uint32_t,
        :sai_adaptation_ind, :uint32_t,
        :sai_assoc_id, :sctp_assoc_t
      )
    end

    class SctpPdapiEvent < FFI::Struct
      layout(
        :pdapi_type, :uint16_t,
        :pdapi_flags, :uint16_t,
        :pdapi_length, :uint32_t,
        :pdapi_indication, :uint32_t,
        :pdapi_stream, :uint32_t,
        :pdapi_seq, :uint32_t,
        :pdapi_assoc_id, :sctp_assoc_t
      )
    end

    class SctpAuthkeyEvent < FFI::Struct
      layout(
        :auth_type, :uint16_t,
        :auth_flags, :uint16_t,
        :auth_length, :uint32_t,
        :auth_keynumber, :uint16_t,
        :auth_indication, :uint32_t,
        :auth_assoc_id, :sctp_assoc_t
      )
    end

    class SctpSenderDryEvent < FFI::Struct
      layout(
        :sender_dry_type, :uint16_t,
        :sender_dry_flags, :uint16_t,
        :sender_dry_length, :uint32_t,
        :sender_dry_assoc_id, :sctp_assoc_t
      )
    end

    class SctpStreamResetEvent < FFI::Struct
      layout(
        :strreset_type, :uint16_t,
        :strreset_flags, :uint16_t,
        :strreset_length, :uint32_t,
        :strreset_assoc_id, :sctp_assoc_t,
        :strreset_stream_list, [:uint16_t, 0]
      )
    end

    class SctpAssocResetEvent < FFI::Struct
      layout(
        :assocreset_type, :uint16_t,
        :assocreset_flags, :uint16_t,
        :assocreset_length, :uint32_t,
        :assocreset_type, :uint16_t,
        :assocreset_assoc_id, :sctp_assoc_t,
        :assocreset_local_tsn, :uint32_t,
        :assocreset_remote_tsn, :uint32_t
      )
    end

    class SctpStreamChangeEvent < FFI::Struct
      layout(
        :strchange_type, :uint16_t,
        :strchange_flags, :uint16_t,
        :strchange_length, :uint32_t,
        :strchange_assoc_id, :sctp_assoc_t,
        :strchange_instrms, :uint16_t,
        :strchange_outstrms, :uint16_t,
      )
    end

    class SctpSendFailedEvent < FFI::Struct
      layout(
        :ssfe_type, :uint16_t,
        :ssfe_flags, :uint16_t,
        :ssfe_length, :uint32_t,
        :ssfe_error, :uint32_t,
        :ssfe_assoc_id, :sctp_assoc_t,
        :ssfe_data, [:uint8_t, 0]
      )
    end

    class SctpEvent < FFI::Struct
      layout(
        :se_assoc_id, :sctp_assoc_t,
        :se_type, :uint16_t,
        :se_on, :uint8_t
      )
    end

    class SctpTlv < FFI::Struct
      layout(
        :sn_type, :uint16_t,
        :sn_flags, :uint16_t,
        :sn_length, :uint32_t
      )
    end

    class SctpNotification < FFI::Union
      layout(:sn_header, SctpTlv)
    end

    class SctpEventSubscribe < FFI::Struct
      layout(
        :sctp_data_io_event, :uint8_t,
        :sctp_association_event, :uint8_t,
        :sctp_address_event, :uint8_t,
        :sctp_send_failure_event, :uint8_t,
        :sctp_peer_error_event, :uint8_t,
        :sctp_shutdown_event, :uint8_t,
        :sctp_partial_deliery_event, :uint8_t,
        :sctp_adaptation_layer_event, :uint8_t,
        :sctp_authentication_event, :uint8_t,
        :sctp_sender_dry_event, :uint8_t,
        :sctp_stream_reset_event, :uint8_t
      )
    end

    class SctpInitMsg < FFI::Struct
      layout(
        :sinit_num_ostreams, :uint16_t,
        :sinit_max_ostreams, :uint16_t,
        :sinit_max_attempts, :uint16_t,
        :sinit_max_init_timeo, :uint16_t
      )
    end

    class SctpRtoinfo < FFI::Struct
      layout(
        :srto_assoc_id, :sctp_assoc_t,
        :srto_initial, :uint32_t,
        :srto_max, :uint32_t,
        :srto_min, :uint32_t
      )
    end

    class SctpAssocparams < FFI::Struct
      layout(
        :sasoc_assoc_id, :sctp_assoc_t,
        :sasoc_peer_rwnd, :uint32_t,
        :sasoc_local_rwnd, :uint32_t,
        :sasoc_cookie_rwnd, :uint32_t,
        :sasoc_asocmaxrxt, :uint16_t,
        :sasoc_number_peer_destinations, :uint16_t
      )
    end

    class SctpSetprim < FFI::Struct
      layout(
        :ssp_addr, SockaddrStorage,
        :ssp_assoc_id, :sctp_assoc_t,
        :ssp_padding, [:uint8_t, 4]
      )
    end

    class SctpSetadaptation < FFI::Struct
      layout(:ssb_adaptation_ind, :uint32_t)
    end

    class SctpPeeraddrparams < FFI::Struct
      layout(
        :spp_address, SockaddrStorage,
        :spp_assoc_id, :sctp_assoc_t,
        :spp_hbinterval, :uint32_t,
        :spp_pathmtu, :uint32_t,
        :spp_flags, :uint32_t,
        :spp_ipv6_flowlabel, :uint32_t,
        :spp_pathmaxrxt, :uint16_t,
        :spp_dscp, :uint8_t,
      )
    end

    class SctpResetStreams < FFI::Struct
      layout(
        :srs_assoc_id, :sctp_assoc_t,
        :srs_flags, :uint16_t,
        :srs_number_streams, :uint16_t,
        :srs_stream_list, :uint16_t
      )
    end

    class SctpAddStreams < FFI::Struct
      layout(
        :sas_assoc_id, :sctp_assoc_t,
        :sas_instrms, :uint16_t,
        :sas_outstrms, :uint16_t
      )
    end

    class SctpHmacalgo < FFI::Struct
      layout(
        :shmac_number_of_idents, :uint32_t,
        :shmac_idents, [:uint16_t, 0]
      )
    end
  end
end
