# == Schema Information
#
# Table name: subscriber_reminders
#
#  id            :bigint           not null, primary key
#  kind          :integer          default("manual"), not null
#  sent_at       :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  message_id    :string
#  subscriber_id :bigint           not null
#
# Indexes
#
#  index_subscriber_reminders_on_message_id              (message_id) UNIQUE
#  index_subscriber_reminders_on_subscriber_id           (subscriber_id)
#  index_subscriber_reminders_on_subscriber_id_and_kind  (subscriber_id,kind)
#
# Foreign Keys
#
#  fk_rails_...  (subscriber_id => subscribers.id)
#
require "rails_helper"

RSpec.describe SubscriberReminder, type: :model do
  it { should belong_to(:subscriber) }
  it { should validate_presence_of(:kind) }
  it { should define_enum_for(:kind).with_values(manual: 0, automatic: 1) }
end
