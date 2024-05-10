require 'mkmf'
require 'rbconfig'

dir_config('sctp')

have_header('netinet/sctp.h')
have_library('sctp')

create_makefile('sctp/socket')
