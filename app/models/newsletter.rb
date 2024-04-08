# == Schema Information
#
# Table name: newsletters
#
#  id                :integer          not null, primary key
#  description       :text
#  dns_records       :json
#  domain            :string
#  domain_verified   :boolean          default(FALSE)
#  email_css         :text
#  email_footer      :string
#  font_preference   :string           default("sans-serif")
#  primary_color     :string           default("#09090b")
#  reply_to          :string
#  sending_address   :string
#  slug              :string           not null
#  status            :string
#  template          :string
#  timezone          :string           default("UTC"), not null
#  title             :string
#  use_custom_domain :boolean
#  website           :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  domain_id         :string
#  user_id           :integer          not null
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

  after_update_commit :setup_custom_domain

  attr_accessor :dkim_tokens

  def setup_custom_domain
    return unless use_custom_domain
    return unless saved_change_to_use_custom_domain?
    return unless saved_change_to_domain?

    remove_old_domain if saved_change_to_domain?

    setup_custom_domain
  end

  private

  def resend_service
    ResendDomainService.new
  end

  def remove_old_domain
    return unless domain_id

    resend_service.delete_domain(domain_id)
  end

  def setup_domain_on_resend
    response = resend_service.create_or_fetch_domain(self.domain, self.domain_id)
    return unless response

    is_verified = response[:status] == "verified"
    update_columns(domain_id: response[:id], dns_records: response[:records], domain_verified: is_verified)

    response
  end
end
