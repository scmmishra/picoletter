module Tokenable
  extend ActiveSupport::Concern

  included do
    class_attribute :token_expiry, instance_writer: false, default: {}
  end

  class_methods do
    def tokenable_on(scope, expiry: nil)
      self.token_expiry[scope] = expiry

      define_method("generate_#{scope}_token") do
        generate_jwt(scope)
      end

      define_method("verify_#{scope}_token") do |token|
        verify_jwt(token, scope)
      end

      define_singleton_method("decode_#{scope}_token") do |token|
        payload = JWT.decode(token, secret_key_base, true, { algorithm: "HS256" }).first
        scope = payload["scope"]
        newsletter = Newsletter.find_by(id: payload["newsletter"])
        subscriber = newsletter.subscribers.find(payload["sub"])

        raise JWT::VerificationError, "Invalid token" unless subscriber

        subscriber.send("verify_#{scope}_token", token)

        subscriber
      end
    end

    def secret_key_base
      AppConfig.get!("SECRET_KEY_BASE")
    end
  end

  private

  def get_payload(scope)
    current_model = self.class.name.downcase
    if current_model == "subscriber"
      { sub: id, newsletter: newsletter.id, iat: Time.current.to_i, scope: scope }
    elsif current_model == "user"
      { user: id, iat: Time.current.to_i, scope: scope }
    else
      raise "Unsupported model for token generation"
    end
  end

  def generate_jwt(scope)
    payload = get_payload(scope)

    if self.class.token_expiry[scope]
      payload["exp"] = (Time.current + self.class.token_expiry[scope]).to_i
    end

    JWT.encode(payload, self.class.secret_key_base, "HS256")
  end

  def verify_jwt(token, scope)
    payload = JWT.decode(token, self.class.secret_key_base, true, { algorithm: "HS256" }).first
    verified = payload["sub"] == id && payload["newsletter"] == newsletter.id && payload["scope"] == scope.to_s
    raise JWT::VerificationError, "Invalid token" unless verified
    payload
  rescue JWT::DecodeError, JWT::ExpiredSignature
    raise JWT::VerificationError, "Invalid token"
  end
end
