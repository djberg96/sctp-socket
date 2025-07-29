require 'ffi'
require_relative 'constants'
require_relative 'structs'

module SCTP
  module Functions
    extend FFI::Library
    ffi_lib 'usrsctp'

    # Initialization
    attach_function :usrsctp_init, [:uint16, :pointer, :pointer], :void
    attach_function :usrsctp_finish, [], :void

    # Socket
    attach_function :usrsctp_socket, [:int, :int, :int, :pointer, :pointer, :uint32, :pointer], :pointer
    attach_function :usrsctp_close, [:pointer], :int
    attach_function :usrsctp_bind, [:pointer, :pointer, :int], :int
    attach_function :usrsctp_connect, [:pointer, :pointer, :int], :int
    attach_function :usrsctp_sendv, [:pointer, :pointer, :size_t, :pointer, :int, :pointer, :socklen_t, :uint32, :uint32, :uint32], :int
    attach_function :usrsctp_setsockopt, [:pointer, :int, :int, :pointer, :socklen_t], :int
    attach_function :usrsctp_getsockopt, [:pointer, :int, :int, :pointer, :pointer], :int
    attach_function :usrsctp_shutdown, [:pointer, :int], :int
    # ...add more as needed...
  end
end
