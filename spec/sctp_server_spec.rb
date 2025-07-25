require 'spec_helper'
require 'sctp/socket'

RSpec.describe SCTP::Server do
  describe '#initialize' do
    it 'creates a server with default options' do
      server = SCTP::Server.new(['127.0.0.1'], 0)
      expect(server).to be_a(SCTP::Server)
      expect(server.addresses).to eq(['127.0.0.1'])
      expect(server.port).to be > 0  # Auto-assigned port
      expect(server.one_to_one).to be false
      server.close
    end

    it 'creates a server in one-to-one mode' do
      server = SCTP::Server.new(['127.0.0.1'], 0, one_to_one: true)
      expect(server.one_to_one).to be true
      server.close
    end

    it 'auto-assigns a port when port is 0' do
      server = SCTP::Server.new(['127.0.0.1'], 0)
      expect(server.port).to be > 0
      expect(server.local_port).to eq(server.port)
      server.close
    end

    it 'binds to all addresses when addresses is nil' do
      server = SCTP::Server.new(nil, 0)
      expect(server.addresses).to be_nil
      server.close
    end
  end

  describe '#addr' do
    it 'returns the bound addresses' do
      server = SCTP::Server.new(['127.0.0.1'], 0)
      addresses = server.addr
      expect(addresses).to be_an(Array)
      expect(addresses).to include('127.0.0.1')
      server.close
    end
  end

  describe '#local_port' do
    it 'returns the bound port number' do
      server = SCTP::Server.new(['127.0.0.1'], 0)
      port = server.local_port
      expect(port).to be_an(Integer)
      expect(port).to be > 0
      server.close
    end
  end

  describe '#closed?' do
    it 'returns false for open server' do
      server = SCTP::Server.new(['127.0.0.1'], 0)
      expect(server.closed?).to be false
      server.close
    end

    it 'returns true after closing' do
      server = SCTP::Server.new(['127.0.0.1'], 0)
      server.close
      expect(server.closed?).to be true
    end
  end

  describe '#close' do
    it 'closes the server socket' do
      server = SCTP::Server.new(['127.0.0.1'], 0)
      expect(server.closed?).to be false
      server.close
      expect(server.closed?).to be true
    end

    it 'does not raise error when called multiple times' do
      server = SCTP::Server.new(['127.0.0.1'], 0)
      server.close
      expect { server.close }.not_to raise_error
    end
  end

  describe '#to_s' do
    it 'shows server info when open' do
      server = SCTP::Server.new(['127.0.0.1'], 0)
      str = server.to_s
      expect(str).to include('SCTP::Server')
      expect(str).to include('127.0.0.1')
      expect(str).to include(server.local_port.to_s)
      expect(str).to include('one-to-many')
      server.close
    end

    it 'shows closed status when closed' do
      server = SCTP::Server.new(['127.0.0.1'], 0)
      server.close
      str = server.to_s
      expect(str).to eq('#<SCTP::Server:closed>')
    end

    it 'shows one-to-one mode correctly' do
      server = SCTP::Server.new(['127.0.0.1'], 0, one_to_one: true)
      str = server.to_s
      expect(str).to include('one-to-one')
      server.close
    end
  end

  describe '#accept (one-to-one mode)' do
    it 'raises error in one-to-many mode' do
      server = SCTP::Server.new(['127.0.0.1'], 0, one_to_one: false)
      expect { server.accept }.to raise_error(/accept.*only available in one-to-one mode/)
      server.close
    end

    # Note: Testing actual accept() would require a client connection
    # which is beyond the scope of basic unit tests
  end

  describe 'socket options' do
    it 'accepts socket options during initialization' do
      expect {
        server = SCTP::Server.new(['127.0.0.1'], 0, autoclose: 30)
        server.close
      }.not_to raise_error
    end
  end
end
