require 'mkmf'

have_header('netinet/sctp.h')
create_makefile('sctp/socket', 'sctp')
