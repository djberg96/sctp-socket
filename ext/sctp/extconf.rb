require 'mkmf'

dir_config('sctp')

if have_header('netinet/sctp.h')
  # Native kernel SCTP (Linux, FreeBSD, etc.)
  header = 'netinet/sctp.h'
  have_library('sctp')
  have_func('sctp_sendv', header)
  have_func('sctp_recvv', header)
else
  # Fall back to usrsctp (primarily for macOS)
  if RUBY_PLATFORM =~ /darwin/
    homebrew_prefix = ENV['HOMEBREW_PREFIX'] || '/opt/homebrew'

    if File.directory?("#{homebrew_prefix}/include")
      $CFLAGS  << " -I#{homebrew_prefix}/include"
      $LDFLAGS << " -L#{homebrew_prefix}/lib"
    end
  end

  unless have_header('usrsctp.h')
    abort <<~MSG

      ERROR: Neither netinet/sctp.h nor usrsctp.h found.

      On macOS:   brew install libusrsctp
      On Ubuntu:  sudo apt-get install libsctp-dev lksctp-tools
      On Fedora:  dnf install lksctp-tools kernel-modules-extra

    MSG
  end

  header = 'usrsctp.h'
  have_library('usrsctp')

  # usrsctp always provides sendv/recvv (as usrsctp_sendv/usrsctp_recvv),
  # so define the feature macros so those code paths compile in.
  $defs << '-DHAVE_SCTP_SENDV=1'
  $defs << '-DHAVE_SCTP_RECVV=1'
end

have_header('sys/param.h')

have_struct_member('struct sctp_event_subscribe', 'sctp_send_failure_event', header)
have_struct_member('struct sctp_event_subscribe', 'sctp_stream_reset_event', header)
have_struct_member('struct sctp_event_subscribe', 'sctp_assoc_reset_event', header)
have_struct_member('struct sctp_event_subscribe', 'sctp_stream_change_event', header)
have_struct_member('struct sctp_event_subscribe', 'sctp_send_failure_event_event', header)

have_struct_member('struct sctp_send_failed_event', 'ssfe_length', header)

have_struct_member('union sctp_notification', 'sn_auth_event', header)

have_const('SCTP_EMPTY', header)

create_makefile('sctp/socket')
