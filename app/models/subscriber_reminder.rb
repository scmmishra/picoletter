# == Schema Information
#
# Table name: subscriber_reminders
#  id             :bigint           not null, primary key
#  kind           :integer          default("manual"), not null
#  message_id     :string
#  sent_at        :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  subscriber_id  :bigint           not null
#
# Indexes
#  index_subscriber_reminders_on_message_id             (message_id) UNIQUE
#  index_subscriber_reminders_on_subscriber_id          (subscriber_id)
#  index_subscriber_reminders_on_subscriber_id_and_kind (subscriber_id,kind)
#
# Foreign Keys
#  fk_rails_...  (subscriber_id => subscribers.id)
#
class SubscriberReminder < ApplicationRecord
  belongs_to :subscriber

  enum :kind, { manual: 0, automatic: 1 }

  validates :kind, presence: true
  validates :message_id, uniqueness: true, allow_nil: true
end
