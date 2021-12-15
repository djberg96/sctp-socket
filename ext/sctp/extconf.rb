require 'mkmf'

have_header('netinet/sctp.h')
have_library('sctp')
have_func('sctp_sendv', 'netinet/sctp.h')
create_makefile('sctp/socket')
