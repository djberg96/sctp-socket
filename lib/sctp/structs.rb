require 'ffi'

module SCTP
  module Structs
    extend FFI::Library

    class Sockaddr < FFI::Struct
      layout(
        :sa_family, :ushort,
        :sa_data, [:char, 14]
      )
    end

    class InAddr < FFI::Struct
      layout(:s_addr, :uint32)
    end

    class SockAddrIn < FFI::Struct
      layout(
        :sin_family, :sa_family_t,
        :sin_port, :in_port_t,
        :sin_addr, InAddr
      )
    end
  end
end
