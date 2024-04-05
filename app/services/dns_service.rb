require "resolv"

class DNSService
  def self.fetch_cname(domain)
    resolver = Resolv::DNS.new
    resources = resolver.getresources(domain, Resolv::DNS::Resource::IN::CNAME)
    resources.map(&:name).first.to_s
  rescue Resolv::ResolvError
    nil
  end

  def self.fetch_mx(domain)
    resolver = Resolv::DNS.new
    resources = resolver.getresources(domain, Resolv::DNS::Resource::IN::MX)
    resources.map(&:exchange).map(&:to_s)
  rescue Resolv::ResolvError
    []
  end

  def self.fetch_txt(domain)
    resolver = Resolv::DNS.new
    resources = resolver.getresources(domain, Resolv::DNS::Resource::IN::TXT)
    resources.map(&:strings).flatten
  rescue Resolv::ResolvError
    []
  end

  def self.verify_record(name, value, type)
    case type
    when "CNAME"
      verify_cname(name, value)
    when "TXT"
      verify_txt(name, value)
    when "MX"
      verify_mx(name, value)
    end
  end

  def self.verify_txt(name, value)
    fetch_txt(name).include?(value)
  end

  def self.verify_cname(name, value)
    fetch_cname(name) == value
  end

  def self.verify_mx(name, value)
    fetch_mx(name).include?(value)
  end
end
