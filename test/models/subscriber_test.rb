# == Schema Information
#
# Table name: subscribers
#
#  id                 :integer          not null, primary key
#  created_via        :string
#  email              :string
#  full_name          :string
#  status             :integer          default("unverified")
#  unsubscribed_at    :datetime
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
require "test_helper"

class SubscriberTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
