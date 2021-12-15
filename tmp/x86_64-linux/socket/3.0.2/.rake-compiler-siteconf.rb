require 'rbconfig'
require 'mkmf'
dest_path = mkintpath("/home/dberger/Dev/sctp-socket/lib/sctp")
RbConfig::MAKEFILE_CONFIG['sitearchdir'] = dest_path
RbConfig::CONFIG['sitearchdir'] = dest_path
RbConfig::MAKEFILE_CONFIG['sitelibdir'] = dest_path
RbConfig::CONFIG['sitelibdir'] = dest_path
