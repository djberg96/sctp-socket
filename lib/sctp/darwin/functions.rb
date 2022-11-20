require 'ffi'

module SCTP
  module Functions
    extend FFI::Library

    ffi_lib :usrsctp

    attach_function :usrsctp_init, %i[udp_port], :void
    attach_function :usrsctp_finish, [], :int
    attach_function :usrsctp_socket, %i[int int int pointer pointer uint32 pointer], :pointer

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
