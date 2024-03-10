# == Schema Information
#
# Table name: posts
#
#  id            :integer          not null, primary key
#  content       :text
#  published_at  :datetime
#  scheduled_at  :datetime
#  status        :string           default("draft")
#  title         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  newsletter_id :integer          not null
#
# Indexes
#
#  index_posts_on_newsletter_id  (newsletter_id)
#
# Foreign Keys
#
#  newsletter_id  (newsletter_id => newsletters.id)
#
require "test_helper"

class PostTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
