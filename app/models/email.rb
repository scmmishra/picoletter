# == Schema Information
#
# Table name: emails
#
#  id            :integer          not null, primary key
#  bounced_at    :datetime
#  delivered_at  :datetime
#  status        :string           default(NULL)
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
class Email < ApplicationRecord
  belongs_to :post
  belongs_to :subscriber

  enum status: { sent: "sent", delivered: "delivered", delivery_delayed: "delivery_delayed", complained: "complained", bounced: "bounced" }
end
