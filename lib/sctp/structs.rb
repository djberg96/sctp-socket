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
  end
end
