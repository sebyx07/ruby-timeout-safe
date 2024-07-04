# frozen_string_literal: true

require_relative 'lib/ruby_timeout_safe/version'

Gem::Specification.new do |spec|
  spec.name = 'ruby-timeout-safe'
  spec.version = RubyTimeoutSafe::VERSION
  spec.authors = ['sebi']
  spec.email = ['gore.sebyx@yahoo.com']

  spec.summary = 'A safe timeout implementation for Ruby using pthreads and signal handling.'
  spec.description = <<~DESC
    ruby-timeout-safe is a Ruby C extension that provides a safe and reliable timeout
    functionality for executing Ruby blocks. It uses POSIX threads (pthreads) and signal
    handling to ensure that timeouts are enforced even in the presence of blocking operations
    or long-running computations.

    The gem defines a `RubyTimeoutSafe` module with a `timeout` method that executes a given
    Ruby block with a specified timeout duration. If the block execution exceeds the timeout,
    a `Timeout::Error` exception is raised.

    The extension supports handling large timeout values (up to the maximum value of `time_t`
    on the system) and raises an `ArgumentError` if a negative timeout value is provided. It
    also defines the `Timeout::Error` exception if it is not already defined in the Ruby
    environment.

    Please note that this extension uses low-level threading and signal handling primitives,
    which may not be compatible with all Ruby implementations or platforms.
  DESC
  spec.homepage = 'https://github.com/sebyx07/ruby-timeout-safe'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.extensions = ['ext/ruby_timeout_safe/extconf.rb']
  spec.add_development_dependency 'rake-compiler'
  spec.add_development_dependency 'rubocop-rails_config', '~> 1.16'
end
