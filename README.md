# Ruby Timeout Safe

ruby-timeout-safe is a Ruby C extension that provides a safe and reliable timeout functionality for executing Ruby blocks. It uses POSIX threads (pthreads) and signal handling to ensure that timeouts are enforced even in the presence of blocking operations or long-running computations.

## Features

- Defines a `RubyTimeoutSafe` module with a `timeout` method that executes a given Ruby block with a specified timeout duration.
- If the block execution exceeds the timeout, a `Timeout::Error` exception is raised.
- Supports handling large timeout values (up to the maximum value of `time_t` on the system).
- Raises an `ArgumentError` if a negative timeout value is provided.
- Defines the `Timeout::Error` exception if it is not already defined in the Ruby environment.
- Handles signals like `SIGTERM` and `SIGINT` by causing the timeout to occur.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby-timeout-safe'
```

And then execute:
`bundle install`

### Usage:
```ruby
require 'ruby_timeout_safe'

# Execute a block with a 2-second timeout
RubyTimeoutSafe.timeout(2) do
  # Your code here
  sleep 1 # This will not raise a timeout error
  # ...
end

# Handling a timeout error
begin
  RubyTimeoutSafe.timeout(1) do
    # Your code here
    sleep 3 # This will raise a Timeout::Error
  end
rescue Timeout::Error => e
  puts "Execution timed out: #{e.message}"
end
```

### Caveats
This extension uses low-level threading and signal handling primitives, which may not be compatible with all Ruby implementations or platforms. It is recommended to use the standard Ruby Timeout module when possible.

### Development
After checking out the repo, run bin/setup to install dependencies. Then, run rake spec to run the tests.

To install this gem onto your local machine, run bundle exec rake install.

### Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/sebyx07/ruby-timeout-safe. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the code of conduct.

### License
The gem is available as open source under the terms of the MIT License.

### Code of Conduct
Everyone interacting in the ruby-timeout-safe project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the code of conduct.