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
#  email_footer      :text             default("")
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
  include Embeddable

  sluggable_on :title

  belongs_to :user
  has_many :subscribers, dependent: :destroy
  has_many :posts, dependent: :destroy

  enum status: { active: "active", archived: "archived" }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  after_update_commit :setup_custom_domain

  attr_accessor :dkim_tokens

  ThemeConfig = Struct.new(:name, :primary, :text_on_primary, :primary_hover, keyword_init: true)

  def description_html
    Kramdown::Document.new(description).to_html.html_safe
  end

  def self.theme_config
    # load colors from conifg/colors.yml
    data = YAML.load_file(Rails.root.join("config", "colors.yml"))
    data.map { |item| ThemeConfig.new(item) }
  end

  def dmarc_record
    {
      "record" => "DMARC",
      "name" => "_dmarc",
      "type" => "TXT",
      "ttl" => "Auto",
      "value" => "v=DMARC1; p=none;",
      "priority" => nil
    }
  end

  def sending_from
    if use_custom_domain && domain_verified
      sending_address
    else
      "#{slug}@mail.picoletter.com"
    end
  end

  def full_sending_address
    "#{title} <#{sending_from}>"
  end

  def setup_custom_domain
    return unless use_custom_domain
    return unless saved_change_to_domain?

    Rails.logger.info("Setting up custom domain: #{domain}")

    remove_old_domain
    setup_domain_on_resend
  end

  def verify_custom_domain
    return unless use_custom_domain

    Rails.logger.info("Verifying custom domain: #{domain}")

    is_verified_on_dns = verify_dns_records
    Rails.logger.info("Domain verification on DNS completed. Verified: #{is_verified_on_dns}")
    return unless is_verified_on_dns

    is_verified, dns_records = verify_domain_on_resend
    Rails.logger.info("Domain verification on Resend completed. Verified: #{is_verified}")
    update_columns(domain_verified: is_verified, dns_records: dns_records)

    is_verified
  end

  def footer_html
    Kramdown::Document.new(self.email_footer || "").to_html
  end

  private

  def remove_old_domain
    return unless domain_id

    Rails.logger.info("Removing old domain: #{domain_id}")
    resend_service.delete_domain(domain_id) if domain_verified
    update_columns(domain_id: nil, domain_verified: false)
    Rails.logger.info("Old domain removed: #{domain_id}")
  end

  def setup_domain_on_resend
    Rails.logger.info("Setting up domain on Resend: #{domain}")
    response = resend_service.create_or_fetch_domain(self.domain, self.domain_id)
    return unless response

    is_verified = response[:status] == "verified"
    update_columns(domain_id: response[:id], dns_records: response[:records], domain_verified: is_verified)

    Rails.logger.info("Domain setup completed. Domain ID: #{response[:id]}, Verified: #{is_verified}")
    response
  end

  def verify_domain_on_resend
    return unless domain_id
    response = resend_service.verify_domain(domain_id)
    is_verified = response[:status] == "verified"

    [ is_verified, response[:records] ]
  end

  def verify_dns_records
    verified = self.dns_records.map do |record|
      name = "#{record["name"]}.#{domain}"
      DNSService.verify_record(name, record["value"], record["type"])
    end

    verified.all?
  end

  def resend_service
    ResendDomainService.new
  end
end
