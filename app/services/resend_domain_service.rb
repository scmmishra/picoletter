class ResendDomainService
  def create_domain(domain)
    Resend::Domains.create({
      name: domain
    })
  end

  def get_domain(domain_id)
    Resend::Domains.get(domain_id)
  end

  def delete_domain(domain_id)
    Resend::Domains.delete(domain_id)
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
