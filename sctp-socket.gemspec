Gem::Specification.new do |spec|
  spec.name        = 'sctp-socket'
  spec.version     = '0.1.2'
  spec.author      = 'Daniel Berger'
  spec.email       = 'djberg96@gmail.com'
  spec.summary     = 'Ruby bindings for SCTP sockets'
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

  spec.metadata = {
    'homepage_uri'          => 'https://github.com/djberg96/sctp-socket',
    'bug_tracker_uri'       => 'https://github.com/djberg96/sctp-socket/issues',
    'changelog_uri'         => 'https://github.com/djberg96/sctp-socket/blob/main/CHANGES.md',
    'documentation_uri'     => 'https://github.com/djberg96/sctp-socket/wiki',
    'source_code_uri'       => 'https://github.com/djberg96/sctp-socket',
    'wiki_uri'              => 'https://github.com/djberg96/sctp-socket/wiki',
    'rubygems_mfa_required' => 'true',
    'funding_uri'           => 'https://github.com/sponsors/djberg96'
  }

  spec.description = <<-EOF
    The sctp-socket library provides Ruby bindings for SCTP sockets. is a
    message oriented, reliable transport protocol with direct support for
    multihoming.
  EOF
end
