require 'rbconfig'

case RbConfig::CONFIG['host_os']
  when /darwin/i
    require_relative 'darwin/socket'
  else
    require_relative 'linux/socket'
end
