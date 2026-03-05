require 'rails_helper'

RSpec.describe SendSubscriberReminderJob, type: :job do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, :with_ready_ses_tenant, user: user) }
  let(:subscriber) { create(:subscriber, newsletter: newsletter, status: :unverified) }
  let(:ses_service) { instance_double(SES::EmailService) }
  let(:ses_response) { Struct.new(:message_id).new("ses-message-id-123") }

  before do
    allow(SES::EmailService).to receive(:new).and_return(ses_service)
    allow(ses_service).to receive(:send).and_return(ses_response)
  end

  describe '#perform' do
    it 'creates a reminder record with message_id and timestamp' do
      expect {
        described_class.perform_now(subscriber.id, kind: :manual)
      }.to change { subscriber.reminders.count }.by(1)

      reminder = subscriber.reminders.last
      expect(reminder.kind).to eq("manual")
      expect(reminder.message_id).to eq("ses-message-id-123")
      expect(reminder.sent_at).to be_within(1.second).of(Time.current)
    end

    it 'creates an email record for webhook tracking' do
      expect {
        described_class.perform_now(subscriber.id, kind: :manual)
      }.to change { Email.count }.by(1)

      email = Email.find("ses-message-id-123")
      expect(email.emailable).to be_a(SubscriberReminder)
      expect(email.subscriber).to eq(subscriber)
    end

    it 'allows specifying the reminder kind' do
      described_class.perform_now(subscriber.id, kind: :automatic)

      reminder = subscriber.reminders.last
      expect(reminder.kind).to eq("automatic")
    end

    it 'sends email via SES with correct parameters' do
      described_class.perform_now(subscriber.id, kind: :manual)

      expect(ses_service).to have_received(:send).with(
        hash_including(
          to: [ subscriber.email ],
          from: newsletter.full_sending_address,
          tenant_name: newsletter.ses_tenant.name,
          subject: "Reminder: Confirm your subscription to #{newsletter.title}"
        )
      )
    end

    it "fails when tenant preflight is not ready" do
      newsletter.ses_tenant.update!(status: :pending)

      expect {
        described_class.perform_now(subscriber.id, kind: :manual)
      }.to raise_error(SES::TenantPreflightFailed)
    end

    it 'reports and re-raises errors from SES' do
      allow(ses_service).to receive(:send).and_raise(StandardError.new("SES failure"))

      expect(Rails.error).to receive(:report).with(
        an_instance_of(StandardError),
        hash_including(context: hash_including(subscriber_id: subscriber.id, kind: :manual), handled: false)
      )

      expect {
        described_class.perform_now(subscriber.id, kind: :manual)
      }.to raise_error(StandardError, "SES failure")
    end
  end
end
