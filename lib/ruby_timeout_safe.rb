# frozen_string_literal: true

require 'timeout'
require_relative 'ruby_timeout_safe/version'

# A safe timeout implementation for Ruby using monotonic time.
module RubyTimeoutSafe
  def self.timeout(seconds = nil)
    return yield if seconds.nil? || seconds.zero?

    current_thread = Thread.current

    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    s_thread = Thread.new do
      loop do
        elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
        break if elapsed_time >= seconds

        Thread.pass
      end
      current_thread.raise Timeout::Error, 'execution expired'
    end

    yield
  ensure
    s_thread.kill if s_thread&.alive?
  end
end
