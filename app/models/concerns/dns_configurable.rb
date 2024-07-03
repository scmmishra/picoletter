module DNSConfigurable
  include ActiveSupport::Concern

  def dmarc_record
    {
      "record" => "DMARC",
      "name" => "_dmarc",
      "type" => "TXT",
      "ttl" => "Auto",
      "value" => "v=DMARC1; p=none;",
      "priority" => nil
    }
  end

  def setup_custom_domain
    return unless use_custom_domain
    return unless saved_change_to_domain?

    Rails.logger.info("Setting up custom domain: #{domain}")

    remove_old_domain
    setup_domain_on_resend
  end

  def verify_custom_domain
    return unless use_custom_domain

    Rails.logger.info("Verifying custom domain: #{domain}")

    is_verified_on_dns = verify_dns_records
    Rails.logger.info("Domain verification on DNS completed. Verified: #{is_verified_on_dns}")
    return unless is_verified_on_dns

    is_verified, dns_records = verify_domain_on_resend
    Rails.logger.info("Domain verification on Resend completed. Verified: #{is_verified}")
    update_columns(domain_verified: is_verified, dns_records: dns_records)

    is_verified
  end

  private

  def remove_old_domain
    return unless domain_id

    Rails.logger.info("Removing old domain: #{domain_id}")
    resend_service.delete_domain(domain_id) if domain_verified
    update_columns(domain_id: nil, domain_verified: false)
    Rails.logger.info("Old domain removed: #{domain_id}")
  end

  def setup_domain_on_resend
    Rails.logger.info("Setting up domain on Resend: #{domain}")
    response = resend_service.create_or_fetch_domain(self.domain, self.domain_id)
    return unless response

    is_verified = response[:status] == "verified"
    update_columns(domain_id: response[:id], dns_records: response[:records], domain_verified: is_verified)

    Rails.logger.info("Domain setup completed. Domain ID: #{response[:id]}, Verified: #{is_verified}")
    response
  end

  def verify_domain_on_resend
    return unless domain_id
    response = resend_service.verify_domain(domain_id)
    is_verified = response[:status] == "verified"

    [ is_verified, response[:records] ]
  end

  def verify_dns_records
    verified = self.dns_records.map do |record|
      name = "#{record["name"]}.#{domain}"
      DNSService.verify_record(name, record["value"], record["type"])
    end

    verified.all?
  end

  def resend_service
    ResendDomainService.new
  end
end
