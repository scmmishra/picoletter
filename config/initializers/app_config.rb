class AppConfig
  class << self
    def get!(env_key)
      value = ENV[env_key]
      raise KeyError, "Environment variable '#{env_key}' is not set" if value.nil?

      value = parse_boolean(value)
      value = parse_integer(value)

      value
    end

    def get(env_key, default_value = nil)
      value = ENV[env_key]
      return default_value if value.nil?

      value = parse_boolean(value)
      value = parse_integer(value)

      value
    end

    private

    def parse_boolean(value)
      case value.downcase
      when "true"
        true
      when "false"
        false
      else
        value
      end
    end

    def parse_integer(value)
      Integer(value) rescue value
    end
  end
end
