require 'rails_helper'

RSpec.describe SendAutomaticRemindersJob, type: :job do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user, auto_reminder_enabled: true) }

  before do
    allow(AppConfig).to receive(:reminders_enabled?).and_return(true)
  end

  describe '#perform' do
    context 'when ENABLE_REMINDERS is false' do
      before do
        allow(AppConfig).to receive(:reminders_enabled?).and_return(false)
      end

      it 'does not process any reminders' do
        create(:subscriber, newsletter: newsletter, status: :unverified, created_at: 24.hours.ago)

        expect {
          described_class.perform_now
        }.not_to have_enqueued_job(SendSubscriberReminderJob)
      end
    end

    context 'when auto_reminder_enabled is true' do
      it 'sends reminders to eligible subscribers' do
        eligible = create(:subscriber, newsletter: newsletter, status: :unverified, created_at: 24.hours.ago)

        expect {
          described_class.perform_now
        }.to have_enqueued_job(SendSubscriberReminderJob).with(eligible.id, kind: :automatic)
      end

      it 'skips subscribers with existing reminders' do
        with_reminder = create(:subscriber, newsletter: newsletter, status: :unverified, created_at: 24.hours.ago)
        create(:subscriber_reminder, subscriber: with_reminder, kind: :manual)

        expect {
          described_class.perform_now
        }.not_to have_enqueued_job(SendSubscriberReminderJob)
      end

      it 'skips subscribers with bounced emails' do
        bounced = create(:subscriber, newsletter: newsletter, status: :unverified, created_at: 24.hours.ago)
        create(:email, subscriber: bounced, status: :bounced)

        expect {
          described_class.perform_now
        }.not_to have_enqueued_job(SendSubscriberReminderJob)
      end

      it 'skips subscribers with complained emails' do
        complained = create(:subscriber, newsletter: newsletter, status: :unverified, created_at: 24.hours.ago)
        create(:email, subscriber: complained, status: :complained)

        expect {
          described_class.perform_now
        }.not_to have_enqueued_job(SendSubscriberReminderJob)
      end

      it 'skips verified subscribers' do
        verified = create(:subscriber, newsletter: newsletter, status: :verified, created_at: 24.hours.ago)

        expect {
          described_class.perform_now
        }.not_to have_enqueued_job(SendSubscriberReminderJob)
      end
    end

    context 'when auto_reminder_enabled is false' do
      it 'does not send any reminders' do
        newsletter.update(auto_reminder_enabled: false)
        create(:subscriber, newsletter: newsletter, status: :unverified, created_at: 24.hours.ago)

        expect {
          described_class.perform_now
        }.not_to have_enqueued_job(SendSubscriberReminderJob)
      end
    end

    context 'error handling' do
      it 'continues processing other subscribers if one fails' do
        sub1 = create(:subscriber, newsletter: newsletter, status: :unverified, created_at: 24.hours.ago)
        sub2 = create(:subscriber, newsletter: newsletter, status: :unverified, created_at: 24.hours.ago)

        # Make the first subscriber raise an error
        allow_any_instance_of(Subscriber).to receive(:send_reminder).and_wrap_original do |method, **args|
          if method.receiver.id == sub1.id
            raise StandardError.new("Test error")
          else
            method.call(**args)
          end
        end

        expect {
          described_class.perform_now
        }.to have_enqueued_job(SendSubscriberReminderJob).with(sub2.id, kind: :automatic)
      end
    end
  end
end
