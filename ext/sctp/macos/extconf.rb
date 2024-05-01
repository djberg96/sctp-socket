require 'mkmf'

dir_config('sctp')

find_header('usrsctp.h', '/usr/local/include')
find_library('usrsctp', nil, '/usr/local/lib')

if have_header('usrsctp.h')
  have_const('SCTP_EMPTY', 'usrsctp.h')
  have_library('usrsctp')
end

create_makefile('sctp/socket')
