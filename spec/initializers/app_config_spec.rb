require 'rails_helper'

RSpec.describe AppConfig do
  describe '.get' do
    it 'returns default value when env var is unset' do
      with_env('ENABLE_BILLING', nil) do
        expect(described_class.get('ENABLE_BILLING', false)).to be(false)
      end
    end

    it 'returns default value when env var is empty' do
      with_env('ENABLE_BILLING', '') do
        expect(described_class.get('ENABLE_BILLING', false)).to be(false)
      end
    end

    it 'parses non-empty values' do
      with_env('ENABLE_BILLING', 'true') do
        expect(described_class.get('ENABLE_BILLING', false)).to be(true)
      end
    end
  end

  describe '.get!' do
    it 'raises KeyError when env var is unset' do
      with_env('R2__PUBLIC_DOMAIN', nil) do
        expect { described_class.get!('R2__PUBLIC_DOMAIN') }.to raise_error(KeyError, /R2__PUBLIC_DOMAIN/)
      end
    end

    it 'raises KeyError when env var is empty' do
      with_env('R2__PUBLIC_DOMAIN', '') do
        expect { described_class.get!('R2__PUBLIC_DOMAIN') }.to raise_error(KeyError, /R2__PUBLIC_DOMAIN/)
      end
    end

    it 'parses non-empty values' do
      with_env('ENABLE_BILLING', 'false') do
        expect(described_class.get!('ENABLE_BILLING')).to be(false)
      end
    end
  end

  def with_env(key, value)
    original_value = ENV[key]
    had_key = ENV.key?(key)

    if value.nil?
      ENV.delete(key)
    else
      ENV[key] = value
    end

    yield
  ensure
    if had_key
      ENV[key] = original_value
    else
      ENV.delete(key)
    end
  end
end
