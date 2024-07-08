require 'ffi'
require_relative 'structs'

module SCTP
  module Functions
    extend FFI::Library
    include SCTP::Structs

    ffi_lib :usrsctp

    callback :receive_cb, [:pointer, SctpSockstore, :pointer, :size_t, SctpRcvinfo, :int], :int
    callback :send_cb, %i[pointer uint32_t], :int
    callback :sctp_outbound_packet, %i[pointer pointer size_t uint8_t uint8_t], :int

    # Callbacks can't have varargs, using a pointer for now
    callback :sctp_debug_printf, %i[string pointer], :void

    attach_function :usrsctp_accept, %i[pointer pointer pointer], :pointer
    attach_function :usrsctp_bind, %i[pointer pointer socklen_t], :int
    attach_function :usrsctp_bindx, %i[pointer pointer int int], :int
    attach_function :usrsctp_close, %i[pointer], :void
    attach_function :usrsctp_connect, %i[pointer pointer pointer], :int
    attach_function :usrsctp_connectx, %i[pointer pointer int pointer], :int
    attach_function :usrsctp_finish, [], :int
    attach_function :usrsctp_getsockopt, %i[pointer int int pointer pointer], :int
    attach_function :usrsctp_init, %i[uint16 sctp_outbound_packet sctp_debug_printf], :void
    attach_function :usrsctp_listen, %i[pointer int], :int
    attach_function :usrsctp_recvv, %i[pointer pointer size_t pointer pointer pointer pointer pointer], :ssize_t
    attach_function :usrsctp_socket, %i[int int int receive_cb send_cb uint32_t pointer], :pointer
    attach_function :usrsctp_sendv, %i[pointer pointer size_t pointer int pointer pointer uint int], :ssize_t
    attach_function :usrsctp_setsockopt, %i[pointer int int pointer pointer], :int
    attach_function :usrsctp_shutdown, %i[pointer int], :int

    # sysctl functions
    attach_function :usrsctp_sysctl_get_sctp_sendspace, [], :uint32_t
    attach_function :usrsctp_sysctl_get_sctp_recvspace, [], :uint32_t
    attach_function :usrsctp_sysctl_get_sctp_hashtblsize, [], :uint32_t
    attach_function :usrsctp_sysctl_get_sctp_pcbtblsize, [], :uint32_t
    attach_function :usrsctp_sysctl_get_sctp_system_free_resc_limit, [], :uint32_t
    attach_function :usrsctp_sysctl_get_sctp_asoc_free_resc_limit, [], :uint32_t
    attach_function :usrsctp_sysctl_get_sctp_mbuf_threshold_count, [], :uint32_t
    attach_function :usrsctp_sysctl_get_sctp_add_more_threshold, [], :uint32_t

    attach_function :usrsctp_sysctl_get_sctp_rto_max_default, [], :uint32_t
    attach_function :usrsctp_sysctl_get_sctp_rto_min_default, [], :uint32_t
    attach_function :usrsctp_sysctl_get_sctp_rto_initial_default, [], :uint32_t
    attach_function :usrsctp_sysctl_get_sctp_init_rto_max_default, [], :uint32_t

    attach_function :usrsctp_sysctl_get_sctp_valid_cookie_life_default, [], :uint32_t
    attach_function :usrsctp_sysctl_get_sctp_heartbeat_interval_default, [], :uint32_t
    attach_function :usrsctp_sysctl_get_sctp_shutdown_guard_time_default, [], :uint32_t
    attach_function :usrsctp_sysctl_get_sctp_pmtu_raise_time_default, [], :uint32_t
    attach_function :usrsctp_sysctl_get_sctp_secret_lifetime_default, [], :uint32_t
    attach_function :usrsctp_sysctl_get_sctp_vtag_time_wait, [], :uint32_t

    ffi_lib :libc

    attach_function :c_bind, :bind, [:int, :pointer, :socklen_t], :int
    attach_function :c_close, :close, [:int], :int
    attach_function :c_inet_addr, :inet_addr, [:string], :in_addr_t
    attach_function :c_shutdown, :shutdown, [:int, :int], :int
    attach_function :c_socket, :socket, [:int, :int, :int], :int
    attach_function :c_strerror, :strerror, [:int], :string
    attach_function :c_htonl, :htonl, [:uint32], :uint32
    attach_function :c_htons, :htons, [:uint16], :uint16
  end
end
