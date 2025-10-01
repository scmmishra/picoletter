module Cloudflare
  class CheckCustomHostnameService < BaseService
    def call
      return disabled_result unless cloudflare_enabled?
      return Result.new(success?: false, error: :missing_cloudflare_id, data: {}) if publishing_domain.cloudflare_id.blank?

      response = perform_request(
        method: :get,
        path: "/accounts/#{account_id!}/custom_hostnames/#{publishing_domain.cloudflare_id}"
      )

      return handle_failure(response) unless response.success?

      apply_success!(response.data)
    end

    private

    def apply_success!(payload)
      ssl_status = payload.dig("ssl", "status")

      publishing_domain.assign_attributes(
        cloudflare_ssl_status: ssl_status,
        last_error: nil
      )
      publishing_domain.apply_http_verification(payload)

      if ssl_status == "active"
        publishing_domain.status = :active
        publishing_domain.verified_at ||= Time.zone.now
      else
        publishing_domain.status = :provisioning
        publishing_domain.verified_at = nil
      end

      publishing_domain.save!

      Result.new(
        success?: true,
        data: {
          ssl_status: publishing_domain.cloudflare_ssl_status,
          hostname: publishing_domain.hostname
        },
        error: nil
      )
    end
  end
end
