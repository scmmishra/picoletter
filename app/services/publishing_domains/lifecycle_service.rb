require "resolv"

module PublishingDomains
  class LifecycleService
    Result = Struct.new(:success?, :data, :error, keyword_init: true)

    attr_reader :publishing_domain

    def initialize(publishing_domain)
      @publishing_domain = publishing_domain
    end

    def register
      return Cloudflare::CreateCustomHostnameService.new(publishing_domain).call if cloudflare_enabled?

      manual_register
    end

    def verify
      return Cloudflare::CheckCustomHostnameService.new(publishing_domain).call if cloudflare_enabled?

      manual_verify
    end

    private

    def manual_register
      publishing_domain.assign_attributes(
        status: :pending,
        cloudflare_id: nil,
        cloudflare_ssl_status: nil,
        verification_method: nil,
        verification_http_body: nil,
        verification_http_path: nil,
        last_error: nil
      )
      publishing_domain.save! if publishing_domain.changed?

      target = platform_hostname

      Result.new(
        success?: true,
        error: nil,
        data: {
          mode: :manual,
          expected_cname: target,
          instructions: "Create a CNAME record pointing #{publishing_domain.hostname} to #{target}."
        }
      )
    end

    def manual_verify
      cname_targets = fetch_cname_targets

      if cname_targets.any? { |value| cname_matches_platform?(value) }
        publishing_domain.update!(status: :active, verified_at: Time.zone.now, last_error: nil)

        Result.new(
          success?: true,
          error: nil,
          data: {
            mode: :manual,
            verified: true,
            hostname: publishing_domain.hostname
          }
        )
      else
        publishing_domain.update!(status: :pending, verified_at: nil, last_error: manual_dns_error_message(cname_targets))

        Result.new(
          success?: false,
          error: :dns_unverified,
          data: {
            mode: :manual,
            expected_cname: platform_hostname,
            resolved_cnames: cname_targets
          }
        )
      end
    end

    def manual_dns_error_message(cname_targets)
      expected = platform_hostname
      return "No CNAME records found for #{publishing_domain.hostname}. Please point it to #{expected}." if cname_targets.blank?

      "Publishing domain CNAME points to #{cname_targets.join(", ")}. Update it to #{expected}."
    end

    def fetch_cname_targets
      Resolv::DNS.open do |dns|
        dns.getresources(publishing_domain.hostname, Resolv::DNS::Resource::IN::CNAME).map do |resource|
          trim_trailing_dot(resource.name.to_s)
        end
      end
    rescue Resolv::ResolvError, SocketError
      []
    end

    def trim_trailing_dot(value)
      value&.end_with?(".") ? value[0..-2] : value
    end

    def cname_matches_platform?(value)
      value.present? && platform_hostname.present? && value.casecmp?(platform_hostname)
    end

    def platform_hostname
      @platform_hostname ||= PublishingDomain.platform_hostname_for(publishing_domain.newsletter)
    end

    def cloudflare_enabled?
      %w[CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID CLOUDFLARE_ZONE_ID].all? do |key|
        AppConfig.get(key, nil).present?
      end
    end
  end
end
