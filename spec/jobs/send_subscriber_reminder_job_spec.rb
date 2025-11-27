require 'rails_helper'

RSpec.describe SendSubscriberReminderJob, type: :job do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user) }
  let(:subscriber) { create(:subscriber, newsletter: newsletter, status: :pending) }

  describe '#perform' do
    it 'creates a reminder record with message_id and timestamp' do
      expect {
        described_class.perform_now(subscriber.id, kind: :manual)
      }.to change { subscriber.reminders.count }.by(1)

      reminder = subscriber.reminders.last
      expect(reminder.kind).to eq("manual")
      expect(reminder.message_id).to be_present
      expect(reminder.sent_at).to be_within(1.second).of(Time.current)
    end

    it 'allows specifying the reminder kind' do
      described_class.perform_now(subscriber.id, kind: :automatic)

      reminder = subscriber.reminders.last
      expect(reminder.kind).to eq("automatic")
    end
  end
end
