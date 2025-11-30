# == Schema Information
#
# Table name: emails
#
#  id             :string           not null, primary key
#  bounced_at     :datetime
#  complained_at  :datetime
#  delivered_at   :datetime
#  emailable_type :string
#  opened_at      :datetime
#  status         :string           default("sent")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  emailable_id   :bigint
#  subscriber_id  :integer
#
# Indexes
#
#  index_emails_on_emailable_type_and_emailable_id  (emailable_type,emailable_id)
#  index_emails_on_subscriber_id                    (subscriber_id)
#
# Foreign Keys
#
#  fk_rails_...  (subscriber_id => subscribers.id)
#
class Email < ApplicationRecord
  include Statusable

  belongs_to :emailable, polymorphic: true
  has_many :clicks, class_name: "EmailClick", dependent: :destroy
  belongs_to :subscriber, optional: true

  enum :status, { sent: "sent", delivered: "delivered", complained: "complained", bounced: "bounced" }
end
