# frozen_string_literal: true

require 'timeout'
require_relative 'ruby_timeout_safe/version'

# A safe timeout implementation for Ruby using monotonic time.
module RubyTimeoutSafe
  def self.timeout(seconds=nil) # rubocop:disable Metrics/MethodLength
    return yield if seconds.nil? || seconds.zero?

    raise ArgumentError, 'timeout value must be at least 0.1 second' if seconds < 0.1
    current_thread = Thread.current

    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    s_thread = Thread.new do
      loop do
        elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
        break if elapsed_time >= seconds

        sleep(0.05) # Sleep briefly to prevent busy-waiting
      end
      current_thread.raise Timeout::Error, 'execution expired'
    end

    yield
  ensure
    s_thread.kill if s_thread&.alive?
  end
end
