require 'mkmf'

have_header('netinet/sctp.h')
have_header('usrsctp.h')
have_library('sctp')
create_makefile('sctp/socket')
