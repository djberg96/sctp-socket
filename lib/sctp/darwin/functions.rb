require 'ffi'

module SCTP
  module Functions
    extend FFI::Library

    ffi_lib :usrsctp

    attach_function :usrsctp_accept, %i[pointer pointer pointer], :pointer
    attach_function :usrsctp_bind, %i[pointer pointer pointer], :int
    attach_function :usrsctp_close, %i[pointer], :void
    attach_function :usrsctp_connect, %i[pointer pointer pointer], :int
    attach_function :usrsctp_init, %i[uint16], :void
    attach_function :usrsctp_finish, [], :int
    attach_function :usrsctp_listen, %i[pointer int], :int
    attach_function :usrsctp_socket, %i[int int int pointer pointer uint32 pointer], :pointer
    attach_function :usrsctp_shutdown, %i[pointer int], :int

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
