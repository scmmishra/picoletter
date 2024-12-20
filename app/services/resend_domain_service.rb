class ResendDomainService
  def create_domain(domain)
    Resend::Domains.create({
      name: domain
    })
  end

  def get_domain(domain_id)
    Resend::Domains.get(domain_id)
  end

  def verify_domain(domain_id)
    # get the domain, if it is already verified, return the domain
    # else verify the domain and return the domain
    domain = Resend::Domains.get(domain_id)
    return domain if domain[:status] == "verified"

    Resend::Domains.verify(domain_id)
  end

  def delete_domain(domain_id)
    Resend::Domains.remove(domain_id)
  rescue StandardError => e
    Rails.logger.error("Error deleting domain: #{e.message}")
  end

  def create_or_fetch_domain(domain, domain_id)
    if domain_id.present?
      response = get_domain(domain_id)
    end

    if response.nil?
      response = create_domain(domain)
    end

    response
  end
end
