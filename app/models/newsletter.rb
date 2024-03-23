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
end
