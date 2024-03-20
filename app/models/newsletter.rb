# == Schema Information
#
# Table name: newsletters
#
#  id          :integer          not null, primary key
#  description :text
#  email_css   :text
#  slug        :string           not null
#  status      :string
#  template    :string
#  timezone    :string           default("UTC"), not null
#  title       :string
#  website     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer          not null
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
end
