# frozen_string_literal: true

require 'mkmf'

# Add any necessary configuration here
# For example, if you need to link against pthread:
$LDFLAGS << ' -pthread' # rubocop:disable Style/GlobalVars

create_makefile('ruby_timeout_safe/ruby_timeout_safe')
