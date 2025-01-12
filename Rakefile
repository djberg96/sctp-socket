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
  t.ext_dir = 'ext/sctp'
  t.lib_dir = 'lib/sctp'
end

desc "Create dummy IP addresses to use for testing"
task :create_dummy_links do
  if RbConfig::CONFIG['host_os'] =~ /linux/i
    system('sudo ip link add dummy1 type dummy')
    system('sudo ip link add dummy2 type dummy')
    system('sudo ip addr add 1.1.1.1/24 dev dummy1')
    system('sudo ip addr add 1.1.1.2/24 dev dummy2')
    system('sudo ip link set dummy1 up')
    system('sudo ip link set dummy2 up')
    system('ip link show')
  else
    system("sudo ifconfig lo1 create")
    system("sudo ifconfig lo1 1.1.1.1/24 up")
    system("sudo ifconfig lo2 create")
    system("sudo ifconfig lo2 1.1.1.2/24 up")
    system("sudo ifconfig -a")
  end
end

RSpec::Core::RakeTask.new

task :spec => :compile
task :default => [:clean, :spec]
