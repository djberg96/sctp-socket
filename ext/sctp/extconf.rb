require 'mkmf'

have_header('netinet/sctp.h')
have_library('sctp')
create_makefile('sctp/socket')
