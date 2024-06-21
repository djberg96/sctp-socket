require 'rbconfig'
require 'mkmf-lite'
include Mkmf::Lite

case RbConfig::CONFIG['host_os']
  when /linux/i
    if have_func('main', 'usrsctp.h')
      require_relative 'usrsctp/socket'
    else
      require_relative 'linux/socket'
    end
  else
    require_relative 'usrsctp/socket'
end
