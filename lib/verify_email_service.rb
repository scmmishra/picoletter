require "resolv"

module VerifyEmailService
  def self.valid?(email)
    address = ValidEmail2::Address.new(email)
    address.valid? && !address.disposable? && address.valid_mx? && !address.deny_listed?
  rescue => e
    Rails.logger.info "[VerifyEmailService] Email verification failed: #{e.message}"
    false
  end
end
