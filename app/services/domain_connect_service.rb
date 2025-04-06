class DomainConnectService
  CACHE_EXPIRY = 7.days
  DOMAIN_CONNECT_RECORD = "_domainconnect"

  def initialize(domain)
    @domain = domain
  end

  def supported?
    Rails.cache.fetch(cache_key("supported"), expires_in: CACHE_EXPIRY) do
      discover_domain_connect.present?
    end
  end

  def settings_url
    Rails.cache.fetch(cache_key("settings_url"), expires_in: CACHE_EXPIRY) do
      discover_domain_connect
    end
  end

  def brand_domain
    AppConfig.get("PICO_SENDING_DOMAIN", "picoletter.com")
  end

  def generate_configuration_url
    return nil unless supported? && settings_url.present?

    params = {
      domain: @domain,
      provider: 'picoletter.com',
      service: 'email'
    }.merge(dns_record_params)

    query = params.to_query
    "https://#{settings_url}/v2/domainTemplates/providers/picoletter.com/services/email/apply?#{query}"
  end

  private

  def discover_domain_connect
    begin
      resolver = Resolv::DNS.new
      records = resolver.getresources(
        "#{DOMAIN_CONNECT_RECORD}.#{@domain}",
        Resolv::DNS::Resource::IN::TXT
      )

      records.map(&:strings).flatten.first
    rescue Resolv::ResolvError => e
      Rails.logger.error "DomainConnect discovery failed for #{@domain}: #{e.message}"
      nil
    end
  end

  def cache_key(type)
    "domainconnect:#{@domain}:#{type}"
  end

  def dns_record_params
    domain = Domain.find_by(name: @domain)
    return {} unless domain

    records = domain.required_dns_records
    {
      mx_record: records[0].slice('name', 'value', 'priority').to_json,
      dkim_record: records[1].slice('name', 'value').to_json,
      spf_record: records[2].slice('name', 'value').to_json
    }
  end

  def ses_service
    @ses_service ||= SES::DomainService.new(@domain)
  end
end
