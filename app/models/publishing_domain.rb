# == Schema Information
#
# Table name: publishing_domains
#
#  id                     :bigint           not null, primary key
#  cloudflare_ssl_status  :string
#  domain_type            :string           default("custom_cname"), not null
#  hostname               :string           not null
#  last_error             :text
#  status                 :string           default("pending"), not null
#  verification_http_body :text
#  verification_http_path :string
#  verification_method    :string
#  verified_at            :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  cloudflare_id          :string
#  newsletter_id          :bigint           not null
#
# Indexes
#
#  index_publishing_domains_on_hostname       (hostname) UNIQUE
#  index_publishing_domains_on_newsletter_id  (newsletter_id) UNIQUE
#
require "uri"

class PublishingDomain < ApplicationRecord
  PLATFORM_DEFAULT_DOMAIN = "picoletter.page".freeze

  belongs_to :newsletter

  enum :domain_type, { custom_cname: "custom_cname" }
  enum :status, { pending: "pending", provisioning: "provisioning", active: "active", failed: "failed" }

  validates :hostname, presence: true, uniqueness: { case_sensitive: false }
  validates :domain_type, presence: true
  validates :status, presence: true
  validates :newsletter_id, uniqueness: true

  before_validation :normalize_hostname

  def self.platform_hostname_for(newsletter)
    base_domain = AppConfig.platform_publishing_domain
    return unless newsletter&.slug.present?

    "#{newsletter.slug}.#{base_domain}"
  end

  def apply_http_verification(payload)
    verification = payload&.dig("ownership_verification_http") || payload&.dig(:ownership_verification_http)
    unless verification.present?
      clear_verification_attributes
      return
    end

    url = verification["http_url"] || verification[:http_url]
    body = verification["http_body"] || verification[:http_body]

    self.verification_http_path = extract_path_from_url(url)
    self.verification_http_body = body.presence
    self.verification_method = verification_http_path.present? && verification_http_body.present? ? "http" : nil
  end

  private

  def normalize_hostname
    self.hostname = hostname&.strip&.downcase
  end

  def clear_verification_attributes
    self.verification_http_path = nil
    self.verification_http_body = nil
    self.verification_method = nil
  end

  def extract_path_from_url(url)
    return if url.blank?

    URI.parse(url).path
  rescue URI::InvalidURIError
    nil
  end
end
