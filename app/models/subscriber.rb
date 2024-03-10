# == Schema Information
#
# Table name: subscribers
#
#  id                 :integer          not null, primary key
#  created_via        :string
#  email              :string
#  full_name          :string
#  status             :integer
#  verification_token :string
#  verified_at        :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  newsletter_id      :integer          not null
#
# Indexes
#
#  index_subscribers_on_newsletter_id  (newsletter_id)
#
# Foreign Keys
#
#  newsletter_id  (newsletter_id => newsletters.id)
#
class Subscriber < ApplicationRecord
  belongs_to :newsletter

  scope :verified, -> { where(status: "verified") }
  enum status: { unverified: 0, verified: 1, unsubscribed: 2 }

  def verify!
    update(status: "verified", verified_at: Time.current)
  end
end
