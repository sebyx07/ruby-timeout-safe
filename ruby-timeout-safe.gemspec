# frozen_string_literal: true

require_relative 'lib/ruby_timeout_safe/version'

Gem::Specification.new do |spec|
  spec.name = 'ruby_timeout_safe'
  spec.version = RubyTimeoutSafe::VERSION
  spec.authors = ['sebi']
  spec.email = ['gore.sebyx@yahoo.com']

  spec.summary = 'A safe timeout implementation for Ruby using monotonic time.'
  spec.description = <<~DESC
    ruby-timeout-safe is a Ruby library that provides a safe and reliable timeout
    functionality for executing Ruby blocks. It uses Ruby's threading and monotonic
    time to ensure that timeouts are enforced even in the presence of blocking operations
    or long-running computations.

    The gem defines a `RubyTimeoutSafe` module with a `timeout` method that executes a given
    Ruby block with a specified timeout duration. If the block execution exceeds the timeout,
    a `Timeout::Error` exception is raised.

    This implementation leverages Ruby's built-in threading and monotonic time functions to
    provide a robust timeout mechanism.
  DESC
  spec.homepage = 'https://github.com/sebyx07/ruby-timeout-safe'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match?(%r{\A(?:bin/|test/|spec/|features/|\.git|\.github|appveyor|Gemfile)})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
