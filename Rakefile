require 'rake'
require 'rake/clean'
require 'rbconfig'
require 'rspec/core/rake_task'
include RbConfig

CLEAN.include(
  '**/*.gem',               # Gem files
  '**/*.rbc',               # Rubinius
  '**/*.o',                 # C object file
  '**/*.log',               # Ruby extension build log
  '**/Makefile',            # C Makefile
  '**/conftest.dSYM',       # OS X build directory
  "**/*.#{CONFIG['DLEXT']}" # C shared object
)

desc "Build the sctp-socket library"
task :build => [:clean] do
  require 'devkit' if CONFIG['host_os'] =~ /mingw|cygwin/i
  Dir.chdir('ext') do
    ruby "extconf.rb"
    sh 'make'
    cp 'socket.so', 'sctp' # For testing
  end
end

RSpec::Core::RakeTask.new(:spec) do |t|
  task :spec => :build
end

task :default => :spec
