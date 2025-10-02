class PublicHostConstraint
  def matches?(request)
    host = request.host&.downcase
    return false if host.blank?

    platform_domain = AppConfig.platform_publishing_domain&.downcase
    return true if platform_subdomain?(host, platform_domain)

    PublishingDomain.active.exists?(hostname: host)
  end

  private

  def platform_subdomain?(host, platform_domain)
    return false if platform_domain.blank?
    return false if host == platform_domain

    host.end_with?(".#{platform_domain}")
  end
end
