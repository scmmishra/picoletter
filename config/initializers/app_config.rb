class AppConfig
  class << self
    def get!(env_key)
      value = ENV[env_key]
      raise KeyError, "Environment variable '#{env_key}' is not set" if value.nil?

      parse_value(value)
    end

    def get(env_key)
      value = ENV[env_key]
      parse_value(value) unless value.nil?
    end

    private

    def parse_value(value)
      case value.downcase
      when "true"
        true
      when "false"
        false
      else
        value
      end
    end
  end
end
