module Cloudflare
  class CreateCustomHostnameService < BaseService
    def call
      return disabled_result unless cloudflare_enabled?
      response = perform_request(
        method: :post,
        path: "/accounts/#{account_id!}/custom_hostnames",
        body: request_body
      )

      return handle_failure(response) unless response.success?

      apply_success!(response.data)
    end

    private

    def apply_success!(payload)
      publishing_domain.assign_attributes(
        cloudflare_id: payload["id"],
        cloudflare_ssl_status: payload.dig("ssl", "status"),
        status: :provisioning,
        last_error: nil
      )
      publishing_domain.apply_http_verification(payload)
      publishing_domain.save!

      Result.new(
        success?: true,
        data: {
          cloudflare_id: publishing_domain.cloudflare_id,
          ssl_status: publishing_domain.cloudflare_ssl_status,
          hostname: publishing_domain.hostname
        },
        error: nil
      )
    end

    def request_body
      {
        hostname: publishing_domain.hostname,
        custom_origin_server: PublishingDomain.platform_hostname_for(publishing_domain.newsletter),
        custom_metadata: custom_metadata,
        ssl: {
          method: "http",
          type: "dv"
        }
      }
    end

    def custom_metadata
      {
        "newsletter_id" => publishing_domain.newsletter_id,
        "publishing_domain_id" => publishing_domain.id,
        "domain_type" => publishing_domain.domain_type
      }
    end
  end
end
