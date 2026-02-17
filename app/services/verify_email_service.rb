require "resolv"

class VerifyEmailService
  def initialize(email)
    @email = ValidEmail2::Address.new(email)
  end

  def valid?
    verify
  end

  def verify
    return false unless @email.valid?
    return false if @email.disposable?
    return false unless @email.valid_mx?
    return false if @email.deny_listed?

    true
  rescue => e
    Rails.logger.info "[VerifyEmailService] Email verification failed: #{e.message}"
    false
  end
end
