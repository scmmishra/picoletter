# == Schema Information
#
# Table name: emails
#
#  id           :integer          not null, primary key
#  bounced_at   :datetime
#  delivered_at :datetime
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
class Email < ApplicationRecord
  belongs_to :post
  enum status: [ :sent, :delivered, :delivery_delayed, :complained, :bounced ]
end
