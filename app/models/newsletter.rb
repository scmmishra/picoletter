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

  def embded_form(with_name: false)
    <<~HTML
    <form
      action="#{Rails.application.config.host}/embed/#{slug}/subscribe"
      method="post"
      target="popupwindow"
      onsubmit="window.open('#{Rails.application.config.host}/#{slug}', 'popupwindow')"
      class="picoletter-form-embed"
    >
      #{ with_name ? "<label for=\"pico-name\">Enter your name</label>\n  <input type=\"text\" name=\"name\" id=\"pico-name\" />" : "" }

      <label for="pico-email">Enter your email</label>
      <input type="email" name="email" id="pico-email" />

      <input type="submit" value="Subscribe" />
      <p>
        <a href="#{Rails.application.config.host}?from=#{slug}" target="_blank">Managed by PicoLetter.</a>
      </p>
    </form>
    HTML
  end

  def embded_form_css(with_name: false)
    <<~CSS
    :root {
      --accent: "#{primary_color}";
      --accent-light: color-mix(in srgb, var(--accent), white 30%);
      --accent-lightest: color-mix(in srgb, var(--accent), white 90%);
      --accent-dark: color-mix(in srgb, var(--accent), black 30%);
      --radius: 0.4rem;
    }

    .picoletter-form-embed {
      display: flex;
      flex-direction: column;
      font-family: ui-sans-serif, system-ui, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji";
    }

    .picoletter-form-embed label {
      font-size: 0.875rem;
      margin-bottom: 0.5rem;
      font-weight: 600;
    }

    .picoletter-form-embed input[type="text"],
    .picoletter-form-embed input[type="email"] {
      padding: 0.5rem;
      border-radius: 0.25rem;
      margin-bottom: 1rem;
      border: 1px solid #ccc;
      border-radius: var(--radius);
    }

    .picoletter-form-embed input[type="submit"] {
      border: 1px solid var(--accent);
      background-color: var(--accent);
      color: var(--accent-lightest);
      padding: 0.5rem 0.9rem;
      text-decoration: none;
      line-height: normal;
      margin-bottom: 0.5rem;
      border-radius: var(--radius);
    }

    .picoletter-form-embed input[type="submit"]:hover {
      background-color: var(--accent-dark);
      border-color: var(--accent-dark);
      cursor: pointer;
    }

    .picoletter-form-embed p {
      margin-block-start: 0px;
      margin-block-end: 0px;
      font-size: 0.75rem;
      color: #666;
    }#{'    '}
    CSS
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
