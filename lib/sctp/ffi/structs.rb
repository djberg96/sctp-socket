require 'ffi'

module SCTP
  module Structs
    extend FFI::Library

    class SctpEventSubscribe < FFI::Struct
      layout :data_io_event, :uint8,
             :association_event, :uint8,
             :address_event, :uint8,
             :send_failure_event, :uint8,
             :peer_error_event, :uint8,
             :shutdown_event, :uint8,
             :partial_delivery_event, :uint8,
             :adaptation_layer_event, :uint8,
             :authentication_event, :uint8,
             :sender_dry_event, :uint8
    end

    class SctpInitMsg < FFI::Struct
      layout :num_ostreams, :uint16,
             :max_instreams, :uint16,
             :max_attempts, :uint16,
             :max_init_timeo, :uint16
    end

    class SctpStatus < FFI::Struct
      layout :assoc_id, :uint32,
             :state, :int32,
             :sstat_rwnd, :uint32,
             :sstat_unackdata, :uint32,
             :sstat_penddata, :uint32,
             :sstat_instrms, :uint16,
             :sstat_outstrms, :uint16,
             :sstat_fragmentation_point, :uint32
    end

    class SctpSndInfo < FFI::Struct
      layout :sid, :uint16,
             :ppid, :uint32,
             :flags, :uint16,
             :context, :uint32,
             :assoc_id, :uint32
    end

    class InAddr < FFI::Struct
      layout :s_addr, :uint32
    end

    class SockAddrIn < FFI::Struct
      if RUBY_PLATFORM =~ /darwin/
        layout :sin_len, :uint8,
               :sin_family, :uint8,
               :sin_port, :uint16,
               :sin_addr, InAddr,
               :sin_zero, [:char, 8]
      else
        layout :sin_family, :uint16,
               :sin_port, :uint16,
               :sin_addr, InAddr,
               :sin_zero, [:char, 8]
      end
    end
  end
end
