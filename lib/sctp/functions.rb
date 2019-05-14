require 'ffi'

module SCTP
  module Functions
    extend FFI::Library
    ffi_lib :sctp

    attach_function :sctp_bindx, [:int, :pointer, :int, :int], :int
    attach_function :sctp_sendmsg, [:int, :pointer, :size_t, :pointer, :pointer, :uint32, :uint32, :uint16, :uint32, :uint32], :int
    #attach_function :sctp_sendv, [:int, :pointer, :int, :pointer, :int, :pointer, :pointer, :uint, :int], :int
    attach_function :sctp_send, [:int, :pointer, :size_t, :pointer, :uint32], :int
    attach_function :sctp_recvmsg, [:int, :pointer, :size_t, :pointer, :pointer, :pointer, :pointer], :int
  end
end
