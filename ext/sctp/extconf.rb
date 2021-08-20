require 'mkmf'

dir_config('sctp')

have_header('netinet/sctp.h')

if have_header('usrsctp.h')
  have_const('SCTP_EMPTY', 'usrsctp.h')
end

have_library('sctp')
have_library('usrsctp')

create_makefile('sctp/socket')
