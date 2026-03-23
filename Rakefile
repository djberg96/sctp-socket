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
  sudo_prefix = Process.uid.zero? ? '' : 'sudo '

  if RbConfig::CONFIG['host_os'] =~ /linux/i
    system("#{sudo_prefix}ip link add dummy1 type dummy")
    system("#{sudo_prefix}ip link add dummy2 type dummy")
    system("#{sudo_prefix}ip addr add 1.1.1.1/24 dev dummy1")
    system("#{sudo_prefix}ip addr add 1.1.1.2/24 dev dummy2")
    system("#{sudo_prefix}ip link set dummy1 up")
    system("#{sudo_prefix}ip link set dummy2 up")
    system("#{sudo_prefix}ip link show")
  else
    system("#{sudo_prefix}ifconfig lo0 alias 1.1.1.1/24 up")
    system("#{sudo_prefix}ifconfig lo0 alias 1.1.1.2/24 up")
    system("#{sudo_prefix}ifconfig lo0")
  end
end

namespace :docker do
  desc "Build the Docker image that contains SCTP test dependencies"
  task :build do
    runtime = container_runtime
    sh runtime, 'build', '-f', 'docker/Dockerfile', '-t', 'sctp-socket-test', '.'
  end

  desc "Run specs inside a privileged Docker container with dummy interfaces"
  task :spec => :build do
    image = ENV.fetch('SCTP_SOCKET_IMAGE', 'sctp-socket-test')
    repo_root = File.expand_path(__dir__)

    runtime = container_runtime

    sh runtime, 'run', '--rm', '--privileged', \
       '--sysctl', 'net.sctp.auth_enable=1', \
       '-v', "#{repo_root}:/app", '-w', '/app', image,
       '/usr/local/bin/run_specs'
  end
end

def container_runtime
  return ENV['CONTAINER_RUNTIME'] unless ENV['CONTAINER_RUNTIME'].to_s.empty?

  if system('command -v podman >/dev/null 2>&1')
    'podman'
  elsif system('command -v docker >/dev/null 2>&1')
    'docker'
  else
    raise 'Neither podman nor docker is installed; please install a container runtime.'
  end
end

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = '-f documentation'
end

task :spec => :compile
task :default => [:clean, :spec]
