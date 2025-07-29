require 'spec_helper'
require 'ipaddr'
require_relative '../lib/sctp/ffi/socket'

RSpec.describe SCTP::Socket do
  let(:port) { 9899 }
  let(:socket) { described_class.new(port: port) }

  after do
    socket.close if socket
  end

  describe '#initialize' do
    it 'creates an SCTP socket' do
      expect(socket.socket).not_to be_nil
    end
  end

  describe '#bind' do
    it 'binds the socket to the port' do
      expect { socket.bind }.not_to raise_error
    end
  end

  describe '#connect' do
    it 'connects to a remote address' do
      # This test will only pass if there is a listening SCTP server on localhost:port
      expect { socket.connect('127.0.0.1', port) }.not_to raise_error
    end
  end

  describe '#send' do
    it 'sends data over SCTP' do
      socket.bind
      expect { socket.send('hello', stream: 0, ppid: 0) }.not_to raise_error
    end
  end

  describe '#close' do
    it 'closes the socket' do
      expect { socket.close }.not_to raise_error
    end
  end
end
