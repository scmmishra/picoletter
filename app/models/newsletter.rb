# == Schema Information
#
# Table name: newsletters
#
#  id                    :bigint           not null, primary key
#  auto_reminder_enabled :boolean          default(TRUE), not null
#  description           :text
#  dns_records           :json
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
#  ses_tenant_id         :string
#  user_id               :integer          not null
#
# Indexes
#
#  index_newsletters_on_ses_tenant_id  (ses_tenant_id)
#  index_newsletters_on_settings       (settings) USING gin
#  index_newsletters_on_slug           (slug)
#  index_newsletters_on_user_id        (user_id)
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
  include Templatable
  include Authorizable

  VALID_URL_REGEX = URI::DEFAULT_PARSER.make_regexp(%w[http https])

  store_accessor :settings, :redirect_after_confirm, :redirect_after_subscribe

  sluggable_on :title

  validates :redirect_after_confirm, format: { with: VALID_URL_REGEX, message: "must be a valid http or https URL" }, allow_blank: true
  validates :redirect_after_subscribe, format: { with: VALID_URL_REGEX, message: "must be a valid http or https URL" }, allow_blank: true
  validates :ses_tenant_id, format: { with: /\A[a-z0-9-]{1,64}\z/ }, allow_nil: true

  belongs_to :user
  has_one :sending_domain, class_name: "Domain", foreign_key: "newsletter_id", dependent: :destroy
  has_many :subscribers, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :labels, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :invitations, dependent: :destroy

  has_many :emails, through: :posts
  has_many :members, through: :memberships, source: :user

  enum :status, { active: "active", archived: "archived" }

  validates :title, presence: true

  after_create :create_owner_membership
  after_create :create_ses_tenant, if: -> { AppConfig.ses_tenants_enabled? }
  before_destroy :cleanup_ses_tenant, if: -> { ses_tenant_id.present? }

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

  def owner?(user)
    self.user_id == user.id
  end

  def member?(user)
    memberships.exists?(user: user)
  end

  def user_role(user)
    return :owner if owner?(user)
    memberships.find_by(user: user)&.role&.to_sym
  end

  def website_host
    return if website.blank?

    URI.parse(website).host
  rescue URI::InvalidURIError
    nil
  end

  def website_label
    website_host.presence || website
  end

  def generate_tenant_name
    "newsletter-#{id}-#{SecureRandom.hex(4)}"
  end

  private

  def create_owner_membership
    memberships.create!(user: user, role: :administrator)
  end

  def create_ses_tenant
    return if ses_tenant_id.present?

    tenant_name = generate_tenant_name
    config_set = AppConfig.get("AWS_SES_CONFIGURATION_SET")

    SES::TenantService.new.create_tenant(tenant_name, config_set)
    update_column(:ses_tenant_id, tenant_name)
  rescue => e
    Rails.logger.error("Failed to create tenant: #{e.message}")
    # Non-blocking: newsletter can function without tenant
  end

  def cleanup_ses_tenant
    tenant_service = SES::TenantService.new

    # Remove domain association if exists
    if sending_domain&.ses_tenant_id.present?
      tenant_service.disassociate_identity(ses_tenant_id, sending_domain.name)
    end

    # Remove configuration set association if exists
    config_set = AppConfig.get("AWS_SES_CONFIGURATION_SET")
    if config_set.present?
      tenant_service.disassociate_configuration_set(ses_tenant_id, config_set)
    end

    # Delete tenant
    tenant_service.delete_tenant(ses_tenant_id)
  rescue => e
    Rails.logger.error("Failed to cleanup tenant: #{e.message}")
  end
end
