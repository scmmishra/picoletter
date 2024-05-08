module Tokenable
  extend ActiveSupport::Concern

  included do
    class_attribute :token_scopes, instance_writer: false, default: {}
  end

  class_methods do
    def tokenable_on(scope, expiry: nil)
      self.token_scopes[scope] = expiry

      define_method("generate_#{scope}_token") do
        generate_jwt(scope)
      end

      define_method("verify_#{scope}_token") do |token|
        verify_jwt(token, scope)
      end
    end
  end

  private

  def generate_jwt(scope)
    payload = {
      sub: id,
      newsletter: newsletter.id,
      iat: Time.current.to_i,
      scope: scope
    }

    if self.class.token_scopes[scope]
      payload["exp"] = (Time.current + self.class.token_scopes[scope]).to_i
    end

    JWT.encode(payload, Rails.application.credentials.secret_key_base, "HS256")
  end

  def verify_jwt(token, scope)
    payload = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: "HS256" }).first
    verified = payload["sub"] == id && payload["newsletter"] == newsletter.id && payload["scope"] == scope.to_s
    raise JWT::VerificationError, "Invalid token" unless verified
    payload
  rescue JWT::DecodeError, JWT::ExpiredSignature
    raise JWT::VerificationError, "Invalid token"
  end
end
