class AppConfig
  class << self
    def get!(env_key)
      value = ENV[env_key]
      raise KeyError, "Environment variable '#{env_key}' is not set" if value.nil?

      value
    end

    def get(env_key)
      ENV[env_key]
    end
  end
end
