require "httparty"

module Cloudflare
  class BaseService
    Result = Struct.new(:success?, :data, :error, keyword_init: true) do
      def failure?
        !success?
      end
    end

    attr_reader :publishing_domain

    def initialize(publishing_domain)
      @publishing_domain = publishing_domain
    end

    private

    def perform_request(method:, path:, body: nil)
      return disabled_result unless cloudflare_enabled?

      response = HTTParty.send(
        method,
        "#{base_url}#{path}",
        headers: headers,
        body: body&.to_json
      )

      if response.success?
        Result.new(success?: true, data: response.parsed_response.fetch("result", {}))
      else
        Result.new(success?: false, error: :api_error, data: failure_payload(response))
      end
    rescue StandardError => e
      Result.new(success?: false, error: :unexpected_error, data: { message: e.message })
    end

    def handle_failure(result)
      record_failure!(result) unless result.error == :cloudflare_disabled
      result
    end

    def record_failure!(result)
      return unless publishing_domain&.persisted?

      data = result.data || {}
      messages = Array(data[:errors]).presence || Array.wrap(data[:message])
      publishing_domain.update(last_error: messages.compact.join("; "), status: :failed)
    end

    def disabled_result
      Result.new(success?: false, error: :cloudflare_disabled, data: {})
    end

    def failure_payload(response)
      parsed = response.parsed_response || {}
      errors = Array(parsed["errors"]).map do |error|
        error.is_a?(Hash) ? error["message"] : error.to_s
      end

      {
        http_status: response.code,
        errors: errors.compact,
        body: parsed
      }
    end

    def headers
      {
        "Authorization" => "Bearer #{api_token}",
        "Content-Type" => "application/json"
      }
    end

    def base_url
      "https://api.cloudflare.com/client/v4"
    end

    def api_token
      @api_token ||= AppConfig.get("CLOUDFLARE_API_TOKEN", nil)
    end

    def account_id
      @account_id ||= AppConfig.get("CLOUDFLARE_ACCOUNT_ID", nil)
    end

    def zone_id
      @zone_id ||= AppConfig.get("CLOUDFLARE_ZONE_ID", nil)
    end

    def cloudflare_enabled?
      api_token.present? && account_id.present? && zone_id.present?
    end

    def account_id!
      account_id || raise("Cloudflare account id missing")
    end
  end
end
