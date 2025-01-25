class VerifyDNSRecordsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[VerifyDNSRecordsJob] Verifying DNS records"

    verified_domains.each do |domain|
      is_verified = domain.verify
      Rails.logger.info "[VerifyDNSRecordsJob] Domain #{domain.name} is verified: #{is_verified}"
      notify_dns_records_broken(domain) unless is_verified
    end
  end

  def verified_domains
    Domain.where(verified: true)
  end

  def notify_dns_records_broken(domain)
    Rails.logger.info "[VerifyDNSRecordsJob] Notifying broken DNS records for #{domain.domain}"
    NewsletterMailer.with(domain: domain).broken_dns_records.deliver_now
  end
end
