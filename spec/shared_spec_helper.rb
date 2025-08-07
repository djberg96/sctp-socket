##############################################################################
# Shared helper for all SCTP::Socket specs
#
# These specs assume you've created two dummy interfaces at 1.1.1.1 and
# 1.1.1.2. Without these the specs will fail.
#
# Run the `rake create_dummy_links` task first to do this for you if needed.
##############################################################################
require 'socket'
require 'sctp/socket'

# Shared configuration and helpers for all SCTP spec files
RSpec.shared_context "sctp_socket_helpers" do
  let(:addresses) { %w[1.1.1.1 1.1.1.2] }
  let(:port) { 12345 }

  before do
    @socket = described_class.new
    @server = described_class.new
  end

  after do
    @socket.close(linger: 0) if @socket
    @server.close(linger: 0) if @server
  end
end

# Include the shared context in all SCTP spec files
RSpec.configure do |config|
  config.include_context "sctp_socket_helpers", type: :sctp_socket
end
