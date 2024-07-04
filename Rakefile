# frozen_string_literal: true

require 'rake/extensiontask'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rake/clean'

CLEAN.include('**/*.o', '**/*.so', '**/*.bundle')
CLOBBER.include('**/Makefile', '**/*.log')

Rake::ExtensionTask.new('ruby_timeout_safe') do |ext|
  ext.lib_dir = 'lib/ruby_timeout_safe'
  ext.ext_dir = 'ext/ruby_timeout_safe'
  ext.source_pattern = '*.{c,h}'
end

RSpec::Core::RakeTask.new(:spec)

task default: %i[compile spec]

desc 'Run tests'
task test: :spec

desc 'Compile and run tests'
task all: %i[compile spec]
