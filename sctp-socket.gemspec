Gem::Specification.new do |spec|
  spec.name        = 'sctp-socket'
  spec.version     = '0.0.3'
  spec.author      = 'Daniel Berger'
  spec.email       = 'djberg96@gmail.com'
  spec.summary     = 'Ruby bindings for SCTP sockets'
  spec.description = 'Ruby bindings for SCTP sockets'
  spec.homepage    = 'https://github.com/djberg96/sctp-socket'
  spec.license     = 'Apache-2.0'
  spec.cert_chain  = ['certs/djberg96_pub.pem']

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.extensions = ['ext/sctp/extconf.rb']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rake-compiler'
  spec.add_development_dependency 'rspec'
end
