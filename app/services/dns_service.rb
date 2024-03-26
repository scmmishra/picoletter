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
end
