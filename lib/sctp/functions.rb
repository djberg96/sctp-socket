require 'ffi'

module SCTP
  module Functions
    extend FFI::Library

    ffi_lib :sctp

    attach_function :sctp_bindx, [:int, :pointer, :int, :int], :int
    attach_function :sctp_connectx, [:int, :pointer, :int, :uint32], :int
    attach_function :sctp_freeladdrs, [:pointer], :void
    attach_function :sctp_freepaddrs, [:pointer], :void
    attach_function :sctp_getladdrs, [:int, :uint32, :pointer], :int
    attach_function :sctp_getpaddrs, [:int, :uint32, :pointer], :int
    attach_function :sctp_opt_info, [:int, :uint32, :int, :pointer, :pointer], :int
    attach_function :sctp_peeloff, [:int, :uint32], :int
    attach_function :sctp_recvmsg, [:int, :pointer, :size_t, :pointer, :pointer, :pointer, :pointer], :int
    attach_function :sctp_send, [:int, :pointer, :size_t, :pointer, :uint32], :int
    attach_function :sctp_sendmsg, [:int, :pointer, :size_t, :pointer, :pointer, :uint32, :uint32, :uint16, :uint32, :uint32], :int

    ffi_lib :libc

    attach_function :close, [:int], :int
    attach_function :inet_addr, [:string], :in_addr_t
    attach_function :shutdown, [:int, :int], :int
    attach_function :socket, [:int, :int, :int], :int
  end
end
