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
    verify_domain_on_resend
  end

  private

  def remove_old_domain
    return unless domain_id

    Rails.logger.info("Removing old domain: #{domain_id}")
    resend_service.delete_domain(domain_id)
    update_column(:domain_id, nil)
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

    Rails.logger.info("Verifying domain on Resend: #{domain_id}")
    response = resend_service.verify_domain(domain_id)
    is_verified = response[:status] == "verified"
    update_column(:domain_verified, is_verified)

    Rails.logger.info("Domain verification completed. Verified: #{is_verified}")
    response
  end

  def verify_dns_records
    verified = self.dns_records.map do |record|
      DNSService.verify_record(record["name"], record["value"], record["type"])
    end
  end

  def resend_service
    ResendDomainService.new
  end
end
