require 'ffi'

module SCTP
  module Structs
    extend FFI::Library

    typedef :int32, :sctp_assoc_t

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

    class SctpSndrcvinfo < FFI::Struct
      layout(
	      :sinfo_stream, :uint16,
	      :sinfo_ssn, :uint16,
	      :sinfo_flags, :uint16,
	      :sinfo_ppid, :uint32,
	      :sinfo_context, :uint32,
	      :sinfo_timetolive, :uint32,
	      :sinfo_tsn, :uint32,
	      :sinfo_cumtsn, :uint32,
	      :sinfo_assoc_id, :sctp_assoc_t
      )
    end
  end
end
