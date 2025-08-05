class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :newsletter

  enum role: {
    administrator: "administrator",
    editor: "editor"
  }

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :newsletter_id }

  scope :administrators, -> { where(role: :administrator) }
  scope :editors, -> { where(role: :editor) }
end
