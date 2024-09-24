class IPShieldService
  def self.legit_ip?(ip)
    return true unless AppConfig.get("IPSHIELD_ADDR", nil).present?
    return true unless Rails.env.production?

    new(ip).legit?
  end

  def initialize(ip)
    @ip = ip
  end

  def legit?
    begin
      result = check_ip
      Rails.logger.info "[IPChecker] #{@ip} status: #{result}"

      result == "SAFE"
    rescue StandardError => e
      Rails.logger.error "[IPChecker] Error checking IP: #{e.message}"
      RorVsWild.record_error(e, context: { ip: @ip })
      true
    end
  end

  private

  def check_ip
    resolver = Resolv::DNS.new(nameserver: [ AppConfig.get!("IPSHIELD_ADDR") ])
    begin
      result = resolver.getresource(@ip, Resolv::DNS::Resource::IN::TXT)
      result.strings.first
    rescue Resolv::ResolvError => e
      raise "Error checking IP: #{e.message}"
    end
  end
end
