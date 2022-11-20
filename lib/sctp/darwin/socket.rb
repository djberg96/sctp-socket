require_relative 'constants'
require_relative 'structs'
require_relative 'functions'
require 'socket'

class SCTPSocket
  include SCTP::Constants
  include SCTP::Functions
  extend SCTP::Structs
  extend SCTP::Functions

  # Create a new SCTP socket using UDP port.
  #
  def initialize(port)
    usrsctp_init(port)
  end

  def close
    usrsctp_finish
  end
end
