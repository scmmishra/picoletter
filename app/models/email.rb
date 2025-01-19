# == Schema Information
#
# Table name: emails
#
#  id            :integer          not null, primary key
#  bounced_at    :datetime
#  complained_at :datetime
#  delivered_at  :datetime
#  opened_at     :datetime
#  status        :string           default("sent")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  post_id       :bigint           not null
#  subscriber_id :integer
#
# Indexes
#
#  index_emails_on_post_id        (post_id)
#  index_emails_on_subscriber_id  (subscriber_id)
#
# Foreign Keys
#
#  fk_rails_...  (post_id => posts.id)
#  fk_rails_...  (subscriber_id => subscribers.id)
#
class Email < ApplicationRecord
  include Statusable

  belongs_to :post
  has_many :clicks, class_name: "EmailClick", dependent: :destroy
  belongs_to :subscriber, optional: true

  enum :status, { sent: "sent", delivered: "delivered", complained: "complained", bounced: "bounced" }
end
