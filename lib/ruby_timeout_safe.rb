# frozen_string_literal: true

require 'timeout'
require_relative 'ruby_timeout_safe/version'

# A safe timeout implementation for Ruby using monotonic time.
module RubyTimeoutSafe
  def self.timeout(seconds) # rubocop:disable Metrics/MethodLength
    raise ArgumentError, 'timeout value must be at least 1 second' if seconds.nil? || seconds < 1.0

    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    thread = Thread.new do
      sleep(seconds)
      Thread.main.raise Timeout::Error, 'execution expired'
    end

    begin
      yield
    ensure
      elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
      remaining_time = seconds - elapsed_time
      thread.kill if remaining_time.positive?
    end
  end
end
