module DNSRecordable
  extend ActiveSupport::Concern

  def dns_records
    [
      {
        "type" => "MX",
        "name" => "mail.#{name}",
        "value" => "feedback-smtp.#{region}.amazonses.com",
        "ttl" => "Auto",
        "priority" => 10,
        "status" => spf_status
      },
      {
        "type" => "TXT",
        "name" => "picoletter._domainkey.#{name}",
        "value" => "p=#{public_key}",
        "ttl" => "Auto",
        "priority" => "",
        "status" => dkim_status
      },
      {
        "type" => "TXT",
        "name" => "mail.#{name}",
        "value" => "v=spf1 include:amazonses.com ~all",
        "ttl" => "Auto",
        "priority" => "",
        "status" => spf_status
      },
      {
        "type" => "TXT",
        "name" => "_dmarc.#{name}",
        "value" => "v=DMARC1; p=none;",
        "ttl" => "Auto",
        "priority" => "",
        "status" => spf_status
      }
    ]
  end

  def required_dns_records
    dns_records.reject { |record| record["name"].start_with?("_dmarc") }
  end

  def optional_dns_records
    dns_records.select { |record| record["name"].start_with?("_dmarc") }
  end
end
