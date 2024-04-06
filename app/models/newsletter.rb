# == Schema Information
#
# Table name: newsletters
#
#  id                        :integer          not null, primary key
#  description               :text
#  dns_records               :json
#  domain                    :string
#  domain_verification_token :string
#  domain_verified           :boolean          default(FALSE)
#  email_css                 :text
#  email_footer              :string
#  font_preference           :string           default("sans-serif")
#  primary_color             :string           default("#09090b")
#  reply_to                  :string
#  sending_address           :string
#  slug                      :string           not null
#  status                    :string
#  template                  :string
#  timezone                  :string           default("UTC"), not null
#  title                     :string
#  use_custom_domain         :boolean
#  website                   :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  domain_id                 :string
#  user_id                   :integer          not null
#
# Indexes
#
#  index_newsletters_on_slug     (slug)
#  index_newsletters_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class Newsletter < ApplicationRecord
  include Sluggable

  sluggable_on :title

  belongs_to :user
  has_many :subscribers, dependent: :destroy
  has_many :posts, dependent: :destroy

  enum status: { active: "active", archived: "archived" }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  after_save :update_ses_domain_verification

  attr_accessor :dkim_tokens

  def dkim_tokens
    domain_verification_token.split(",")
  end

  def dns_records
    return [] unless use_custom_domain

    records = dkim_tokens.map do |token|
      {
        name: "#{token}._domainkey.#{domain}",
        type: "CNAME",
        value: "#{token}.dkim.amazonses.com"
      }
    end

    records + [
      {
        name: "_dmarc.#{domain}",
        type: "TXT",
        value: "v=DMARC1;p=quarantine;rua=mailto:report@#{domain};"
      },
      {
        name: "send.#{domain}",
        value: "v=spf1 include:amazonses.com ~all",
        type: "TXT"
      }
    ]
  end

  def verify_domain
    return false unless use_custom_domain

    if !verify_dns_records
      update(domain_verified: false)
      return false
    end

    verify_ses_identity

    verified = is_verified_on_ses?
    update(domain_verified: verified)

    verified
  end

  private

  def verify_dns_records
    verified = dns_records.map do |record|
      is_verified = DNSService.verify_record(record[:name], record[:value], record[:type])
      Rails.logger.info "DNS record #{record[:name]} is verified: #{is_verified}"
      is_verified
    end

    verified.all?
  end

  def verify_ses_identity
    ses_verification_service.verify_ses_identity(domain)
  end

  def is_verified_on_ses?
    ses_verification_service.verified?(domain)
  end

  def update_ses_domain_verification
    # if `use_custom_domain` changes to true, create a new SES domain verification token
    return unless saved_change_to_use_custom_domain? or saved_change_to_domain?
    return unless use_custom_domain

    tokens = ses_verification_service.create_tokens(domain)
    update(domain_verification_token: tokens.join(","))
  end

  def ses_verification_service
    SESVerificationService.new
  end
end
