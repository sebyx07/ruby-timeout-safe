# frozen_string_literal: true

RSpec.describe RubyTimeoutSafe do # rubocop:disable Metrics/BlockLength
  it 'raises a Timeout::Error if the block execution time exceeds the limit' do
    expect do
      RubyTimeoutSafe.timeout(1) { sleep 2 }
    end.to raise_error(Timeout::Error, 'execution expired')
  end

  it 'does not raise a Timeout::Error if the block execution time is within the limit' do
    expect do
      RubyTimeoutSafe.timeout(2) { sleep 1 }
    end.not_to raise_error
  end

  it 'returns the value of the block if it completes within the limit' do
    result = RubyTimeoutSafe.timeout(2) { 42 }
    expect(result).to eq(42)
  end

  it 'handles SIGTERM and raises a Timeout::Error' do
    expect do
      RubyTimeoutSafe.timeout(2) do
        Process.kill('TERM', Process.pid)
        sleep 3
      end
    end.to raise_error(Timeout::Error, 'execution expired')
  end

  it 'does not raise a Timeout::Error if the block raises a different error' do
    expect do
      RubyTimeoutSafe.timeout(2) { raise 'some other error' }
    end.to raise_error(RuntimeError, 'some other error')
  end
end
