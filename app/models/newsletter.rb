# == Schema Information
#
# Table name: newsletters
#
#  id                    :bigint           not null, primary key
#  auto_reminder_enabled :boolean          default(TRUE), not null
#  description           :text
#  dns_records           :json
#  domain                :string
#  domain_verified       :boolean          default(FALSE)
#  email_css             :text
#  email_footer          :text             default("")
#  enable_archive        :boolean          default(TRUE)
#  font_preference       :string           default("sans-serif")
#  primary_color         :string           default("#09090b")
#  reply_to              :string
#  sending_address       :string
#  sending_name          :string
#  settings              :jsonb            not null
#  slug                  :string           not null
#  status                :string
#  template              :string
#  timezone              :string           default("UTC"), not null
#  title                 :string
#  website               :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  domain_id             :string
#  user_id               :integer          not null
#
# Indexes
#
#  index_newsletters_on_settings  (settings) USING gin
#  index_newsletters_on_slug      (slug)
#  index_newsletters_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Newsletter < ApplicationRecord
  include Sluggable
  include Embeddable
  include Statusable
  include Themeable

  VALID_URL_REGEX = URI::DEFAULT_PARSER.make_regexp(%w[http https])

  store_accessor :settings, :redirect_after_confirm, :redirect_after_subscribe

  sluggable_on :title

  validates :redirect_after_confirm, format: { with: VALID_URL_REGEX, message: "must be a valid http or https URL" }, allow_blank: true
  validates :redirect_after_subscribe, format: { with: VALID_URL_REGEX, message: "must be a valid http or https URL" }, allow_blank: true

  belongs_to :user
  has_one :sending_domain, class_name: "Domain", foreign_key: "newsletter_id"
  has_many :subscribers, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :labels, dependent: :destroy

  has_many :emails, through: :posts

  enum :status, { active: "active", archived: "archived" }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :auto_reminder_enabled, inclusion: { in: [ true, false ] }

  scope :with_auto_reminders_enabled, -> { where(auto_reminder_enabled: true) }

  attr_accessor :dkim_tokens

  def description_html
    return "" if description.blank?
    Kramdown::Document.new(description).to_html.html_safe
  end

  def verify_custom_domain
    sending_domain&.verify
  end

  def ses_verified?
    sending_domain&.verified?
  end

  def footer_html
    Kramdown::Document.new(self.email_footer || "").to_html
  end

  def sending_from
    if ses_verified?
      sending_address
    else
      default_sending_domain = AppConfig.get("PICO_SENDING_DOMAIN", "picoletter.com")
      # separt mail. address to maintain deliverability of the default domain
      "#{slug}@mail.#{default_sending_domain}"
    end
  end

  def full_sending_address
    "#{sending_name || title} <#{sending_from}>"
  end
end
