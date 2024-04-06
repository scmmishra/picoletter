class VerifyDNSRecordsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[VerifyDNSRecordsJob] Verifying DNS records"

    newsletters_with_custom_domain.each do |newsletter|
      is_verified = newsletter.verify_domain
      Rails.logger.info "[VerifyDNSRecordsJob] Domain #{newsletter.domain} is verified: #{is_verified}"
      notify_dns_records_broken(newsletter) unless is_verified
    end
  end

  def newsletters_with_custom_domain
    Newsletter.where(use_custom_domain: true)
  end

  def notify_dns_records_broken(newsletter)
    Rails.logger.info "[VerifyDNSRecordsJob] Notifying broken DNS records for #{newsletter.domain}"
    NewsletterMailer.with(newsletter: newsletter).broken_dns_records.deliver_now
  end
end
