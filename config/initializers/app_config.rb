class AppConfig
  def self.billing_enabled?
    AppConfig.get("ENABLE_BILLING", false)
  end

  class << self
    def get!(env_key)
      value = ENV[env_key]
      raise KeyError, "Environment variable '#{env_key}' is not set" if value.nil?

      parse_value(value)
    end

    def get(env_key, default_value = nil)
      value = ENV[env_key]
      return default_value if value.nil?

      parse_value(value)
    end

    private

    def parse_value(value)
      return parse_boolean(value) if boolean?(value)
      return parse_number(value) if numeric?(value)
      value
    end

    def parse_boolean(value)
      case value.downcase
      when "true" then true
      when "false" then false
      end
    end

    def parse_number(value)
      begin
        Integer(value)
      rescue ArgumentError
        value
      end
    end

    def boolean?(value)
      value.downcase.match?(/\A(true|false)\z/)
    end

    def numeric?(value)
      value.match?(/\A-?\d+\z/)
    end
  end
end
