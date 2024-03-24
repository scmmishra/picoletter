# == Schema Information
#
# Table name: newsletters
#
#  id                        :integer          not null, primary key
#  description               :text
#  domain                    :string
#  domain_verification_token :string
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

    dkim_tokens.map do |token|
      {
        name: "#{token}._domainkey.#{domain}",
        type: "CNAME",
        value: "#{token}.dkim.amazonses.com"
      }
    end
  end

  private

  def update_ses_domain_verification
    # if `use_custom_domain` changes to true, create a new SES domain verification token
    return unless saved_change_to_use_custom_domain? or saved_change_to_domain?
    return unless use_custom_domain

    ses_verification_service = SesVerificationService.new
    tokens = ses_verification_service.create_tokens(domain)
    update(domain_verification_token: tokens.join(","))
  end
end
