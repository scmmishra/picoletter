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
      result = nil
      bm = Benchmark.measure do
        result = check_ip
      end

      duration_ms = bm.real * 1000
      Rails.logger.info "[IPShieldService] #{@ip} status: #{result}, duration: #{duration_ms.round(2)}ms, user CPU time: #{(bm.utime * 1000).round(2)}ms, system CPU time: #{(bm.stime * 1000).round(2)}ms"

      result == "SAFE"
    rescue StandardError => e
      Rails.logger.error "[IPShieldService] Error checking IP: #{e.message}"
      Rails.error.report(e, context: { ip: @ip })
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
