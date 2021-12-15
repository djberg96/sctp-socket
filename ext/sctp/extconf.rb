require 'mkmf'

have_header('netinet/sctp.h')
have_library('sctp')
have_func('sctp_sendv', 'netinet/sctp.h')
have_struct_member('struct sctp_event_subscribe', 'sctp_send_failure_event', 'netinet/sctp.h')
create_makefile('sctp/socket')
