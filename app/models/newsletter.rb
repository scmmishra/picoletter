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
  class AlreadyMemberError < StandardError; end
  class ExistingInvitationError < StandardError; end
  class InvitationError < StandardError; end
  class InvalidDomainError < StandardError; end
  class DomainClaimedError < StandardError; end

  include Sluggable
  include Embeddable

  include Themeable
  include Templatable
  include Authorizable

  VALID_URL_REGEX = URI::DEFAULT_PARSER.make_regexp(%w[http https])
  DOMAIN_NAME_REGEX = /\A[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+\z/i

  store_accessor :settings, :redirect_after_confirm, :redirect_after_subscribe

  sluggable_on :title

  validates :redirect_after_confirm, format: { with: VALID_URL_REGEX, message: "must be a valid http or https URL" }, allow_blank: true
  validates :redirect_after_subscribe, format: { with: VALID_URL_REGEX, message: "must be a valid http or https URL" }, allow_blank: true
  validates :sending_address, presence: true, if: :sending_domain_connected?

  belongs_to :user
  has_one :sending_domain, class_name: "Domain", foreign_key: "newsletter_id"
  has_many :subscribers, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :labels, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :api_tokens, dependent: :destroy

  has_many :emails, through: :posts
  has_many :members, through: :memberships, source: :user

  enum :status, { active: "active", archived: "archived" }

  validates :title, presence: true

  after_create :create_owner_membership
  before_validation :ensure_sending_address_for_connected_domain

  attr_accessor :dkim_tokens

  def description_html
    return "" if description.blank?
    ActionController::Base.helpers.sanitize(Kramdown::Document.new(description).to_html)
  end

  def verify_custom_domain
    sending_domain&.verify
  end

  def ses_verified?
    sending_domain&.verified?
  end

  def footer_html
    Kramdown::Document.new(email_footer || "").to_html
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
    user_id == user.id
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

  def invite_member(email:, role:, invited_by:)
    normalized = email.to_s.strip.downcase

    raise AlreadyMemberError, "#{email} is already a member of this newsletter." if memberships.joins(:user).where("LOWER(users.email) = ?", normalized).exists?
    raise ExistingInvitationError, "An invitation has already been sent to #{email}." if invitations.pending.for_email(normalized).exists?

    invitation = invitations.build(email: normalized, role: role, invited_by: invited_by)

    unless invitation.save
      raise InvitationError, "Failed to send invitation: #{invitation.errors.full_messages.join(', ')}"
    end

    InvitationMailer.with(invitation: invitation).team_invitation.deliver_now
    invitation
  end

  def disconnect_sending_domain
    return unless sending_domain.present?

    sending_domain.drop_identity
    sending_domain.destroy!
    update!(sending_address: nil, sending_name: nil, reply_to: nil)
  rescue Aws::SESV2::Errors::NotFoundException => e
    Rails.logger.error("Domain not found in SES: #{e.message}, cleaning up locally")
    sending_domain.destroy!
    update!(sending_address: nil, sending_name: nil, reply_to: nil)
  end

  def connect_sending_domain(domain_name)
    normalized_domain_name = domain_name.to_s.strip.downcase

    raise InvalidDomainError, "Domain name invalid" unless valid_domain_name?(normalized_domain_name)
    raise DomainClaimedError, "Domain already in use" if Domain.claimed_by_other?(normalized_domain_name, id)
    raise InvalidDomainError, "A domain is already connected. Disconnect it first." if Domain.exists?(newsletter_id: id)

    domain = nil
    ActiveRecord::Base.transaction do
      domain = create_sending_domain!(name: normalized_domain_name)
      domain.register
      update!(sending_address: sender_address_for(normalized_domain_name))
    end
  rescue ActiveRecord::RecordNotUnique
    raise InvalidDomainError, "A domain is already connected. Disconnect it first." if Domain.exists?(newsletter_id: id)
    raise DomainClaimedError, "Domain already in use"
  rescue StandardError
    cleanup_registered_identity(domain)
    raise
  end

  private

  def valid_domain_name?(domain_name)
    domain_name.present? && domain_name.match?(DOMAIN_NAME_REGEX)
  end

  def sender_address_for(domain_name)
    current_address = sending_address.to_s.strip
    existing_local_part, existing_domain_part = current_address.split("@", 2)

    if current_address.present? && existing_local_part.present? && existing_domain_part.present? && existing_domain_part.casecmp?(domain_name)
      return current_address
    end

    local_part = existing_local_part.to_s.strip.presence || generated_sender_local_part
    "#{local_part}@#{domain_name}"
  end

  def generated_sender_local_part
    preferred_name = user.name.to_s.split.first
    raw_local_part = preferred_name.presence || slug.presence || "newsletter-#{id}"
    normalized_local_part = I18n.transliterate(raw_local_part).downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")

    normalized_local_part.presence || slug.presence || "newsletter-#{id}"
  end

  def cleanup_registered_identity(domain)
    return if domain.blank?

    domain.drop_identity
  rescue Aws::SESV2::Errors::NotFoundException
    nil
  rescue StandardError => e
    Rails.error.report(e, context: { newsletter_id: id, domain: domain.name })
  end

  def create_owner_membership
    memberships.create!(user: user, role: :administrator)
  end

  def sending_domain_connected?
    sending_domain.present?
  end

  def ensure_sending_address_for_connected_domain
    return unless sending_domain_connected?
    return if sending_address.present?

    self.sending_address = sender_address_for(sending_domain.name)
  end
end
