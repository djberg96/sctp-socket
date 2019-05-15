require_relative 'constants'
require_relative 'structs'
require_relative 'functions'

class SCTPSocket
  include SCTP::Constants
  extend SCTP::Structs
  extend SCTP::Functions

  def initialize
  end
end
