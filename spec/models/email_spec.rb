# == Schema Information
#
# Table name: emails
#
#  id            :integer          not null, primary key
#  bounced_at    :datetime
#  delivered_at  :datetime
#  status        :string           default("sent")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  email_id      :string
#  post_id       :integer          not null
#  subscriber_id :integer
#
# Indexes
#
#  index_emails_on_post_id        (post_id)
#  index_emails_on_subscriber_id  (subscriber_id)
#
# Foreign Keys
#
#  post_id        (post_id => posts.id)
#  subscriber_id  (subscriber_id => subscribers.id)
#
require 'rails_helper'

RSpec.describe Email, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
