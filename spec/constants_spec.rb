require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  context "constants" do
    example "SCTP_CLOSED" do
      expect(described_class::SCTP_CLOSED).to be_a(Integer)
    end

    example "SCTP_COOKIE_WAIT" do
      expect(described_class::SCTP_COOKIE_WAIT).to be_a(Integer)
    end

    example "SCTP_COOKIE_ECHOED" do
      expect(described_class::SCTP_COOKIE_ECHOED).to be_a(Integer)
    end

    example "SCTP_ESTABLISHED" do
      expect(described_class::SCTP_ESTABLISHED).to be_a(Integer)
    end

    example "SCTP_SHUTDOWN_PENDING" do
      expect(described_class::SCTP_SHUTDOWN_PENDING).to be_a(Integer)
    end

    example "SCTP_SHUTDOWN_SENT" do
      expect(described_class::SCTP_SHUTDOWN_SENT).to be_a(Integer)
    end

    example "SCTP_SHUTDOWN_RECEIVED" do
      expect(described_class::SCTP_SHUTDOWN_RECEIVED).to be_a(Integer)
    end

    example "SCTP_SHUTDOWN_ACK_SENT" do
      expect(described_class::SCTP_SHUTDOWN_ACK_SENT).to be_a(Integer)
    end

    example "SCTP_BINDX_ADD_ADDR" do
      expect(described_class::SCTP_BINDX_ADD_ADDR).to be_a(Integer)
    end

    example "SCTP_BINDX_REM_ADDR" do
      expect(described_class::SCTP_BINDX_REM_ADDR).to be_a(Integer)
    end

    example "SCTP_UNORDERED" do
      expect(described_class::SCTP_UNORDERED).to be_a(Integer)
    end

    example "SCTP_ADDR_OVER" do
      expect(described_class::SCTP_ADDR_OVER).to be_a(Integer)
    end

    example "SCTP_ABORT" do
      expect(described_class::SCTP_ABORT).to be_a(Integer)
    end

    example "SCTP_EOF" do
      expect(described_class::SCTP_EOF).to be_a(Integer)
    end

    example "SCTP_SENDALL" do
      expect(described_class::SCTP_SENDALL).to be_a(Integer)
    end

    example "MSG_NOTIFICATION" do
      expect(described_class::MSG_NOTIFICATION).to be_a(Integer)
    end
  end
end
