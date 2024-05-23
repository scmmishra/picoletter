# == Schema Information
#
# Table name: emails
#
#  id           :integer          not null, primary key
#  delivered_at :datetime
#  sent_at      :datetime
#  status       :string           default(NULL)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  email_id     :string
#  post_id      :integer          not null
#
# Indexes
#
#  index_emails_on_post_id  (post_id)
#
# Foreign Keys
#
#  post_id  (post_id => posts.id)
#
require "test_helper"

class EmailTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
