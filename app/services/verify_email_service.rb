require "net/smtp"
require "resolv"

class VerifyEmailService
  attr_reader :email

  def initialize(email)
    @email = email
  end

  def verify
    return false unless valid_format?

    domain = email.split("@").last
    mx_records = fetch_mx_records(domain)

    return false if mx_records.empty?

    smtp_server = mx_records.first.exchange.to_s
    verify_smtp(smtp_server)
  rescue => e
    Rails.logger.error "Email verification failed: #{e.message}"
    false
  end

  private

  def valid_format?
    email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  end

  def fetch_mx_records(domain)
    Resolv::DNS.open do |dns|
      dns.getresources(domain, Resolv::DNS::Resource::IN::MX)
    end
  end

  def verify_smtp(smtp_server)
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
