class VerifyDNSRecordsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[VerifyDNSRecordsJob] Verifying DNS records"

    Domain.verified.each do |domain|
      is_verified = domain.verify
      Rails.logger.info "[VerifyDNSRecordsJob] Domain #{domain.name} is verified: #{is_verified}"
      notify_dns_records_broken(domain) unless is_verified
    end
  end

  def notify_dns_records_broken(domain)
    Rails.logger.info "[VerifyDNSRecordsJob] Notifying broken DNS records for #{domain.domain}"
    NewsletterMailer.with(domain: domain).broken_dns_records.deliver_now
  end
end
