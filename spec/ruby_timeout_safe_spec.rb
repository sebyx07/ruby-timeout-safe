# frozen_string_literal: true

RSpec.describe RubyTimeoutSafe do # rubocop:disable Metrics/BlockLength
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

  it 'handles Bignum values for timeout' do
    expect do
      RubyTimeoutSafe.timeout(10**10) { 42 }
    end.not_to raise_error
  end
end
