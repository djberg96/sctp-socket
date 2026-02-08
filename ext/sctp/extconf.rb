require 'mkmf'

dir_config('sctp')

# On macOS with Homebrew, add its prefix so headers/libs can be found.
if RUBY_PLATFORM =~ /darwin/
  homebrew_prefix = ENV['HOMEBREW_PREFIX'] || '/opt/homebrew'

  if File.directory?("#{homebrew_prefix}/include")
    $CFLAGS  << " -I#{homebrew_prefix}/include"
    $LDFLAGS << " -L#{homebrew_prefix}/lib"
  end
end

have_header('arpa/inet.h')

# Prefer libusrsctp if found.
if have_header('usrsctp.h')
  have_library('usrsctp')
else
  have_header('netinet/sctp.h')
  have_library('sctp')
  have_func('sctp_sendv', 'netinet/sctp.h')
  have_func('sctp_recvv', 'netinet/sctp.h')
  have_struct_member('struct sctp_event_subscribe', 'sctp_send_failure_event', 'netinet/sctp.h')
end

create_makefile('sctp/socket')
