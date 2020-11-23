require 'rake'
require 'rake/clean'
require 'rbconfig'
require 'rspec/core/rake_task'
require 'rake/extensiontask'
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

Rake::ExtensionTask.new('socket') do |t|
  t.ext_dir = 'ext/sctp'
  t.lib_dir = 'lib/sctp'
end

RSpec::Core::RakeTask.new

task :spec => :compile
task :default => :spec
