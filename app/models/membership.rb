# == Schema Information
#
# Table name: memberships
#
#  id            :bigint           not null, primary key
#  role          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  newsletter_id :bigint           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_memberships_on_newsletter_id              (newsletter_id)
#  index_memberships_on_role                       (role)
#  index_memberships_on_user_id                    (user_id)
#  index_memberships_on_user_id_and_newsletter_id  (user_id,newsletter_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#  fk_rails_...  (user_id => users.id)
#
class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :newsletter

  enum :role, {
    administrator: "administrator",
    editor: "editor"
  }

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :newsletter_id }

  scope :administrators, -> { where(role: :administrator) }
  scope :editors, -> { where(role: :editor) }
end
