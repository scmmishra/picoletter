require "net/smtp"
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

  def verify_mx
    @email.valid_mx?
  end

  def verify_smtp
    domain = email.split("@").last
    mx_records = mx_servers_for_domain(domain)

    mx_records.any? { |mx| verify_smtp_hello(mx) }
  rescue => e
    Rails.logger.info "[VerifyEmailService] SMTP verification failed: #{e.message}"
    false
  end

  private

  def verify_smtp_hello(smtp_server)
    Net::SMTP.start(smtp_server, 25, "localhost") do |smtp|
      smtp.helo "localhost"
      smtp.mailfrom "verify@example.com"
      smtp.rcptto email
      true
    end
  rescue Net::SMTPFatalError
    false
  end
end
