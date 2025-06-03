require "resolv"

namespace :email_providers do
  desc "Verify all email provider hosts from config/email_providers.yml"
  task verify: :environment do
    puts "🔍 Verifying email provider hosts..."
    puts "=" * 60

    providers = YAML.load_file(Rails.root.join("config", "email_providers.yml"))

    total_hosts = 0
    valid_hosts = 0
    invalid_hosts = []

    providers.each do |provider|
      puts "\n📧 #{provider['name']} (#{provider['hosts'].count} hosts)"
      puts "-" * 40

      provider["hosts"].each do |host|
        total_hosts += 1

        dns_valid = verify_dns(host)
        mx_valid = verify_mx_record(host, provider["mx_regex"])

        status = case
        when dns_valid && mx_valid
                  valid_hosts += 1
                  "✅ VALID"
        when dns_valid && !mx_valid
                  "⚠️  DNS OK, NO MX"
        else
                  invalid_hosts << { provider: provider["name"], host: host, dns: dns_valid, mx: mx_valid }
                  "❌ INVALID"
        end

        puts "  #{host.ljust(25)} #{status}"
      end
    end

    puts "\n" + "=" * 60
    puts "📊 SUMMARY"
    puts "=" * 60
    puts "Total hosts: #{total_hosts}"
    puts "Valid hosts: #{valid_hosts}"
    puts "Invalid hosts: #{invalid_hosts.count}"
    puts "Success rate: #{((valid_hosts.to_f / total_hosts) * 100).round(2)}%"

    if invalid_hosts.any?
      puts "\n❌ INVALID HOSTS:"
      puts "-" * 20
      invalid_hosts.each do |invalid|
        dns_status = invalid[:dns] ? "DNS ✅" : "DNS ❌"
        mx_status = invalid[:mx] ? "MX ✅" : "MX ❌"
        puts "  #{invalid[:provider]} - #{invalid[:host]} (#{dns_status}, #{mx_status})"
      end
    end

    puts "\n🏁 Verification complete!"
  end

  private

  def verify_dns(host)
    Resolv.getaddress(host)
    true
  rescue Resolv::ResolvError
    false
  end

  def verify_mx_record(host, mx_regex)
    mx_records = get_mx_records(host)
    return false if mx_records.empty?

    # If no regex pattern is provided, just check if MX records exist
    return true if mx_regex.nil? || mx_regex.empty?

    # Check if MX records match the expected regex pattern
    mx_hostnames = mx_records.map { |mx| mx.split(" ").last.downcase }.join(" ")
    regex = Regexp.new(mx_regex, Regexp::IGNORECASE)

    mx_hostnames.match?(regex)
  end

  def get_mx_records(host)
    resolver = Resolv::DNS.new
    begin
      mx_records = resolver.getresources(host, Resolv::DNS::Resource::IN::MX)
      mx_records.map { |mx| "#{mx.preference} #{mx.exchange}" }
    rescue Resolv::ResolvError
      []
    end
  end
end
