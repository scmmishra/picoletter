require "net/smtp"
require "resolv"

class VerifyEmailService
  attr_reader :email

  def initialize(email)
    @email = email
  end

  def verify
    return false unless valid_format?
    return false if disposable?

    true
  rescue => e
    Rails.logger.error "Email verification failed: #{e.message}"
    false
  end

  def verify_mx
    domain = email.split("@").last
    mx_records = mx_servers_for_domain(domain)

    return mx_records.present?
  rescue => e
    Rails.logger.error "Email verification failed: #{e.message}"
    false
  end

  def verify_smtp
    domain = email.split("@").last
    mx_records = mx_servers_for_domain(domain)

    mx_records.any? { |mx| verify_smtp(mx) }
  rescue => e
    Rails.logger.error "Email verification failed: #{e.message}"
    false
  end

  private

  def disposable?
    email_domains = YAML.load_file(Rails.root.join("config", "disposable_emails.yml"))
    email_domains.any? { |domain| email.ends_with?(domain) }
  end

  def valid_format?
    email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  end

  def mx_servers_for_domain(domain)
    Rails.cache.fetch("mx_servers:#{domain}", expires_in: 7.day) do
      fetch_mx_records(domain)
    end
  end

  def fetch_mx_records(domain)
    Resolv::DNS.open do |dns|
      dns.getresources(domain, Resolv::DNS::Resource::IN::MX)
        .sort_by(&:preference)
        .map { |mx| mx.exchange.to_s }
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
