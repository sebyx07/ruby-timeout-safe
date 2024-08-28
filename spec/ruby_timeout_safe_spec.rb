# frozen_string_literal: true

RSpec.describe RubyTimeoutSafe do
  describe 'multiple time calls' do
    3.times do |i|
      it "#{i} raises a Timeout::Error if the block execution time exceeds the limit" do
        expect do
          RubyTimeoutSafe.timeout(1) { sleep 100 }
        end.to raise_error(Timeout::Error, 'execution expired')
      end
    end
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

  it 'does not raise a Timeout::Error if the block raises a different error' do
    expect do
      RubyTimeoutSafe.timeout(2) { raise 'some other error' }
    end.to raise_error(RuntimeError, 'some other error')
  end

  it 'raises an ArgumentError if the timeout value is less than 0.1 second' do
    expect do
      RubyTimeoutSafe.timeout(0.01) { sleep 0.01 }
    end.to raise_error(ArgumentError, 'timeout value must be at least 0.1 second')
  end

  it 'handles Bignum values for timeout' do
    expect do
      RubyTimeoutSafe.timeout(10**10) { 42 }
    end.not_to raise_error
  end
end
