require 'mkmf'

dir_config('sctp')

have_header('netinet/sctp.h')
have_header('usrsctp.h')

have_library('sctp')
have_library('usrsctp')

create_makefile('sctp/socket')
