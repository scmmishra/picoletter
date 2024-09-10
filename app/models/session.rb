# == Schema Information
#
# Table name: sessions
#
#  id         :bigint           not null, primary key
#  active     :boolean
#  token      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_sessions_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Session < ApplicationRecord
  has_secure_token
  belongs_to :user
end
