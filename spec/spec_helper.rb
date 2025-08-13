require 'socket'
require_relative 'shared_spec_helper'

# Include the shared context in all SCTP spec files
RSpec.configure do |config|
  config.include_context "sctp_socket_helpers", type: :sctp_socket
  config.filter_run_excluding(:bsd) unless RbConfig::CONFIG['host_os'] =~ /bsd|dragonfly/
end
