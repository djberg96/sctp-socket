Gem::Specification.new do |spec|
  spec.name          = 'sctp-socket'
  spec.version       = '0.1.0'
  spec.authors       = ['Daniel Berger', 'Dávid Halász']
  spec.email         = ['djberg96@gmail.com', 'skateman@skateman.eu']

  spec.summary       = 'Ruby bindings for SCTP sockets'
  spec.description   = 'Ruby bindings for SCTP sockets'
  spec.homepage      = 'https://github.com/djberg96/sctp-sockets'
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.extensions    = ['ext/extconf.rb']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rake-compiler'
  spec.add_development_dependency 'rspec'
end
