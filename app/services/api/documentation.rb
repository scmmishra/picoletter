require "digest"

module Api
  class Documentation
    METHOD_ORDER = %w[get post patch put delete].freeze
    SUCCESS_RESPONSE_CODES = %w[200 201].freeze

    class << self
      def cache_version
        Digest::SHA256.hexdigest((Rails.configuration.x.openapi_spec || {}).to_json)
      end

      def endpoints(base_url:)
        spec = Rails.configuration.x.openapi_spec || {}
        server_prefix = spec.fetch("servers", []).first&.fetch("url", "").to_s

        spec.fetch("paths", {}).each_with_object([]) do |(path, operations), docs|
          METHOD_ORDER.each do |method|
            operation = operations[method]
            next unless operation

            full_path = join_paths(server_prefix, path)
            docs << {
              title: operation["summary"].presence || "#{method.upcase} #{full_path}",
              method: method.upcase,
              path: full_path,
              samples: code_samples(operation, method, full_path, base_url),
              params: endpoint_params(operation, spec),
              response: success_response_example(operation)
            }.compact
          end
        end
      end

      private

      def join_paths(prefix, suffix)
        cleaned_prefix = prefix.to_s.sub(%r{/*\z}, "")
        cleaned_suffix = suffix.to_s.start_with?("/") ? suffix.to_s : "/#{suffix}"
        "#{cleaned_prefix}#{cleaned_suffix}".presence || "/"
      end

      def endpoint_params(operation, spec)
        params = []

        Array(operation["parameters"]).each do |parameter|
          params << {
            name: parameter["name"],
            required: parameter["required"] == true,
            description: parameter["description"].presence || default_parameter_description(parameter)
          }
        end

        body_schema = dereference_schema(
          operation.dig("requestBody", "content", "application/json", "schema"),
          spec
        )
        if body_schema
          required = Array(body_schema["required"])
          body_schema.fetch("properties", {}).each do |name, schema|
            params << {
              name: name,
              required: required.include?(name),
              description: schema["description"].presence || default_schema_description(schema)
            }
          end
        end

        params.presence
      end

      def success_response_example(operation)
        response = SUCCESS_RESPONSE_CODES.lazy.map { |code| operation.dig("responses", code) }.find(&:present?)
        return unless response

        content = response.dig("content", "application/json")
        return unless content

        example = content["example"]
        if example.blank?
          first_example = content["examples"]&.values&.first
          example = first_example&.dig("value")
        end
        return unless example

        JSON.pretty_generate(example)
      end

      def code_samples(operation, method, api_path, base_url)
        samples = Array(operation["x-codeSamples"]).map do |sample|
          {
            label: sample["label"].presence || sample["lang"].presence || "Sample",
            lang: sample["lang"].presence || "bash",
            code: interpolate_sample_source(sample["source"].to_s, base_url: base_url, api_path: api_path)
          }
        end

        samples.presence || [ fallback_sample(method, api_path, base_url) ]
      end

      def interpolate_sample_source(source, base_url:, api_path:)
        source
          .gsub("{{BASE_URL}}", base_url)
          .gsub("{{API_PATH}}", api_path)
          .gsub("{{URL}}", "#{base_url}#{api_path}")
      end

      def fallback_sample(method, api_path, base_url)
        method_name = method.to_s.upcase
        command = +"curl -X #{method_name} \"#{base_url}#{api_path}\" \\\n  -H \"Authorization: Bearer your_api_token\""
        if %w[POST PATCH PUT].include?(method_name)
          command << " \\\n  -H \"Content-Type: application/json\" \\\n  -d '{}'"
        end

        { label: "cURL", lang: "bash", code: command }
      end

      def dereference_schema(schema, spec)
        return unless schema
        return schema unless schema.is_a?(Hash) && schema["$ref"].present?

        ref_name = schema["$ref"].split("/").last
        spec.dig("components", "schemas", ref_name)
      end

      def default_parameter_description(parameter)
        source = parameter["in"].to_s
        type = resolve_type(parameter["schema"])
        "#{source.capitalize} parameter (#{type})"
      end

      def default_schema_description(schema)
        "Request field (#{resolve_type(schema)})"
      end

      def resolve_type(schema)
        return "value" unless schema.is_a?(Hash)

        type = schema["type"]
        if type.is_a?(Array)
          non_nullable = type - [ "null" ]
          type = non_nullable.first
        end

        type.presence || "value"
      end
    end
  end
end
