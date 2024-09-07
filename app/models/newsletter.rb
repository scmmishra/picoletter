# == Schema Information
#
# Table name: newsletters
#
#  id                :bigint           not null, primary key
#  description       :text
#  dns_records       :json
#  domain            :string
#  domain_verified   :boolean          default(FALSE)
#  email_css         :text
#  email_footer      :text             default("")
#  enable_archive    :boolean          default(TRUE)
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
#  fk_rails_...  (user_id => users.id)
#
class Newsletter < ApplicationRecord
  include Sluggable
  include Embeddable
  include Statusable
  include Themeable
  include DNSConfigurable

  sluggable_on :title

  belongs_to :user
  has_many :subscribers, dependent: :destroy
  has_many :posts, dependent: :destroy

  enum status: { active: "active", archived: "archived" }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  after_update_commit :setup_custom_domain

  attr_accessor :dkim_tokens

  def description_html
    Kramdown::Document.new(description).to_html.html_safe
  end

  def footer_html
    Kramdown::Document.new(self.email_footer || "").to_html
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
end
