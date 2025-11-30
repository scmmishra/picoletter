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
FactoryBot.define do
  factory :subscriber_reminder do
    subscriber
    kind { :manual }
    message_id { nil }
    sent_at { nil }

    trait :automatic do
      kind { :automatic }
    end

    trait :sent do
      sequence(:message_id) { |n| "reminder-message-#{n}" }
      sent_at { Time.current }
    end
  end
end
