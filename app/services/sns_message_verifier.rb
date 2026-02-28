require "base64"
require "net/http"
require "openssl"
require "uri"

class SNSMessageVerifier
  CERT_PATH_PATTERN = %r{\A/SimpleNotificationService-[A-Za-z0-9]+\.pem\z}.freeze
  SNS_HOST_PATTERN = /\A(?:sns|sns-fips)(?:\.[a-z0-9-]+)?\.amazonaws\.com(?:\.cn)?\z/i
  SIGNABLE_KEYS = {
    "Notification" => %w[Message MessageId Subject Timestamp TopicArn Type],
    "SubscriptionConfirmation" => %w[Message MessageId SubscribeURL Timestamp Token TopicArn Type],
    "UnsubscribeConfirmation" => %w[Message MessageId SubscribeURL Timestamp Token TopicArn Type]
  }.freeze

  def initialize(payload)
    @payload = payload.with_indifferent_access
  end

  def authentic?
    return false unless required_fields_present?
    return false unless supported_signature_version?
    return false unless self.class.valid_signing_cert_url?(@payload[:SigningCertURL])

    certificate = fetch_signing_certificate
    return false unless certificate

    digest = digest_for(@payload[:SignatureVersion].to_s)
    return false unless digest

    signature = Base64.strict_decode64(@payload[:Signature].to_s)
    certificate.public_key.verify(digest, signature, string_to_sign)
  rescue StandardError
    false
  end

  def self.valid_signing_cert_url?(url)
    uri = parse_https_uri(url)
    return false unless uri
    return false unless aws_sns_host?(uri.host)
    return false if uri.query.present?
    return false unless uri.path.match?(CERT_PATH_PATTERN)

    true
  end

  def self.valid_subscription_confirmation_url?(url)
    uri = parse_https_uri(url)
    return false unless uri
    return false unless aws_sns_host?(uri.host)
    return false if uri.query.blank?

    params = Rack::Utils.parse_query(uri.query)
    params["Action"] == "ConfirmSubscription" &&
      params["Token"].present? &&
      params["TopicArn"].present?
  rescue ArgumentError
    false
  end

  private

  def required_fields_present?
    @payload[:Type].present? &&
      @payload[:Signature].present? &&
      @payload[:SignatureVersion].present? &&
      @payload[:SigningCertURL].present? &&
      string_to_sign.present?
  end

  def supported_signature_version?
    %w[1 2].include?(@payload[:SignatureVersion].to_s)
  end

  def digest_for(signature_version)
    case signature_version
    when "1" then OpenSSL::Digest::SHA1.new
    when "2" then OpenSSL::Digest::SHA256.new
    end
  end

  def fetch_signing_certificate
    uri = URI.parse(@payload[:SigningCertURL].to_s)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
      http.get(uri.request_uri)
    end

    return unless response.is_a?(Net::HTTPSuccess)

    OpenSSL::X509::Certificate.new(response.body)
  rescue StandardError
    nil
  end

  def string_to_sign
    keys = SIGNABLE_KEYS[@payload[:Type].to_s]
    return unless keys

    fragments = keys.each_with_object([]) do |key, signed_fragments|
      value = @payload[key]
      if key == "Subject"
        next if value.blank?
      elsif value.blank?
        return nil
      end

      signed_fragments << "#{key}\n#{value}"
    end

    "#{fragments.join("\n")}\n"
  end

  def self.parse_https_uri(url)
    uri = URI.parse(url.to_s)
    return unless uri.is_a?(URI::HTTPS)
    return if uri.host.blank?
    return if uri.user.present? || uri.password.present?
    return if uri.fragment.present?
    return if uri.port != URI::HTTPS::DEFAULT_PORT

    uri
  rescue URI::InvalidURIError
    nil
  end

  def self.aws_sns_host?(host)
    host.match?(SNS_HOST_PATTERN)
  end

  private_class_method :parse_https_uri, :aws_sns_host?
end
