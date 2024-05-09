require 'rake'
require 'rake/clean'
require 'rbconfig'
require 'rspec/core/rake_task'
require 'rake/extensiontask'
include RbConfig

CLEAN.include(
  '**/*.gem',                # Gem files
  '**/*.rbc',                # Rubinius
  '**/*.o',                  # C object file
  '**/*.log',                # Ruby extension build log
  '**/Makefile',             # C Makefile
  '**/conftest.dSYM',        # OS X build directory
  "**/*.#{CONFIG['DLEXT']}", # C shared object
  'tmp'                      # Rake compiler
)

namespace :gem do
  desc "Create the sys-uname gem"
  task :create => [:clean] do
    require 'rubygems/package'
    spec = Gem::Specification.load('sctp-socket.gemspec')
    spec.signing_key = File.join(Dir.home, '.ssh', 'gem-private_key.pem')
    Gem::Package.build(spec)
  end

  desc "Install the sys-uname gem"
  task :install => [:create] do
    file = Dir["*.gem"].first
    sh "gem install -l #{file}"
  end
end

Rake::ExtensionTask.new('socket') do |t|
  if RbConfig::CONFIG['host_os'] =~ /linux/i
    t.ext_dir = 'ext/linux/sctp'
    t.lib_dir = 'lib/linux/sctp'
  else
    t.ext_dir = 'ext/macos/sctp'
    t.lib_dir = 'lib/macos/sctp'
  end
end

RSpec::Core::RakeTask.new(:spec) do |t|
  case RbConfig::CONFIG['host_os']
    when /linux/i
      t.rspec_opts = '-Ilib/linux'
    when /macos|darwin/i
      t.rspec_opts = '-Ilib/macos'
  end
end

task :spec => :compile
task :default => [:clean, :spec]
