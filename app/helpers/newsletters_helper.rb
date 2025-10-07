module NewslettersHelper
  def public_newsletter_home_url(newsletter)
    active_domain = newsletter.publishing_domain

    if active_domain&.active?
      "https://#{active_domain.hostname}"
    else
      hostname = newsletter.platform_hostname
      if hostname.present?
        public_newsletter_url(host: hostname, protocol: "https")
      else
        public_newsletter_url
      end
    end
  end
end
