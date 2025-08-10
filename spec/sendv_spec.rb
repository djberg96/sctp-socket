require_relative 'shared_spec_helper'

RSpec.describe SCTP::Socket, type: :sctp_socket do
  include_context 'sctp_socket_helpers'

  context "sendv" do
    before do
      @server.bindx(:addresses => addresses, :port => port, :reuse_addr => true)
      @server.listen

      @socket.connectx(:addresses => addresses, :port => port)
    end

    example "sendv basic functionality" do
      expect(@socket).to respond_to(:sendv)
    end

    example "sendv requires a hash argument" do
      expect { @socket.sendv("not a hash") }.to raise_error(TypeError)
      expect { @socket.sendv(123) }.to raise_error(TypeError)
      expect { @socket.sendv(nil) }.to raise_error(TypeError)
    end

    example "sendv requires message parameter" do
      expect { @socket.sendv({}) }.to raise_error(ArgumentError, "message parameter is required")
    end

    example "sendv validates message parameter type" do
      expect { @socket.sendv({ message: "not an array" }) }.to raise_error(TypeError)
      expect { @socket.sendv({ message: 123 }) }.to raise_error(TypeError)
      expect { @socket.sendv({ message: nil }) }.to raise_error(ArgumentError, "message parameter is required")
    end

    example "sendv validates addresses parameter type" do
      options = { message: ["test"] }

      expect { @socket.sendv(options.merge(addresses: "not an array")) }.to raise_error(TypeError)
      expect { @socket.sendv(options.merge(addresses: 123)) }.to raise_error(TypeError)

      # Valid addresses parameter (array) should not raise TypeError
      expect { @socket.sendv(options.merge(addresses: ["1.1.1.1", "1.1.1.2"])) }.not_to raise_error
    end

    example "sendv validates message array contents" do
      expect { @socket.sendv({ message: [] }) }.to raise_error(ArgumentError, "Must contain at least one message")
    end

    example "sendv ignores unknown hash keys" do
      options = {
        message: ["test"],
        unknown_key: "ignored",
        another_unknown: 123
      }
      expect(@socket.sendv(options)).to eq(options[:message].first.length)
    end

    example "sendv with connection emCallError" do
      @server.close(linger: 0) if @server rescue nil
      options = { message: ["Hello", "World"] }
      expect{ @socket.sendv(options) }.to raise_error(SystemCallError)
    end

    example "sendv accepts multiple message parts" do
      options = { message: ["Hello ", "World", "!"] }
      expect(@socket.sendv(options)).to eq(options[:message].sum(&:size))
    end

    example "sendv with nil optional parameters" do
      options = {
        message: ["test"],
        stream: nil,
        ppid: nil,
        context: nil,
        flags: nil,
        ttl: nil,
        addresses: nil,
        port: nil
      }
      expect(@socket.sendv(options)).to eq(options[:message].first.size)
    end
  end
end
