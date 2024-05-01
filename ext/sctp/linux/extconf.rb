require 'mkmf'
require 'rbconfig'

dir_config('sctp')

case RbConfig::CONFIG['host_os']
  when /linux/i
    have_header('netinet/sctp.h')
    have_library('sctp')
  when /darwin|macos/i
    find_header('usrsctp.h', '/usr/local/include')
    find_library('usrsctp', nil, '/usr/local/lib')
    if have_header('usrsctp.h')
      have_const('SCTP_EMPTY', 'usrsctp.h')
      have_library('usrsctp')
    end
end

create_makefile('sctp/socket')
