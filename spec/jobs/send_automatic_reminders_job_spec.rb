require 'rails_helper'

RSpec.describe SendAutomaticRemindersJob, type: :job do
  describe '#perform' do
    let(:newsletter) { create(:newsletter, auto_reminder_enabled: true) }

    let!(:eligible_subscriber) do
      create(:subscriber,
        newsletter: newsletter,
        status: 'unverified',
        created_at: 25.hours.ago
      )
    end

    let!(:ineligible_subscriber) do
      create(:subscriber,
        newsletter: newsletter,
        status: 'verified',
        created_at: 25.hours.ago
      )
    end

    before do
      # Stub logger to avoid output during tests
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:debug)
      allow(Rails.logger).to receive(:error)
      # Enable scheduling by default for tests
      allow(AppConfig).to receive(:get).with("ENABLE_AUTO_REMINDERS", false).and_return(true)
      allow(AppConfig).to receive(:get).with("REMINDER_BATCH_SIZE", 50).and_return(50)
    end

    it 'processes eligible subscribers and sends reminders' do
      expect {
        described_class.new.perform
      }.to have_enqueued_mail(SubscriptionMailer, :confirmation_reminder)

      eligible_subscriber.reload
      expect(eligible_subscriber.reminder_sent?).to be true
    end

    it 'does not process ineligible subscribers' do
      described_class.new.perform

      ineligible_subscriber.reload
      expect(ineligible_subscriber.reminder_sent?).to be false
    end

    it 'logs processing information' do
      expect(Rails.logger).to receive(:info).with(/Processing batch of \d+ eligible subscribers/)
      expect(Rails.logger).to receive(:info).with(/Completed: \d+ sent, \d+ failed/)

      described_class.new.perform
    end

    it 'logs successful reminder sends in debug mode' do
      expect(Rails.logger).to receive(:debug).with(/Sent reminder to subscriber #{eligible_subscriber.id}/)

      described_class.new.perform
    end

    it 'processes all subscribers in batches' do
      stub_const("#{described_class}::BATCH_SIZE", 1)

      # Create one more eligible subscriber
      second_subscriber = create(:subscriber,
        newsletter: newsletter,
        status: 'unverified',
        created_at: 25.hours.ago
      )

      # Should process both subscribers even with batch size of 1
      expect(Subscriber).to receive(:claim_for_reminder).exactly(2).times.and_call_original

      described_class.new.perform

      # Both subscribers should have reminders sent
      eligible_subscriber.reload
      second_subscriber.reload
      expect(eligible_subscriber.reminder_sent?).to be true
      expect(second_subscriber.reminder_sent?).to be true
    end

    context 'when reminder sending fails' do
      before do
        allow_any_instance_of(Subscriber).to receive(:send_reminder).and_raise(StandardError.new("Email service error"))
        allow(RorVsWild).to receive(:record_error)
      end

      it 'handles errors gracefully and continues processing' do
        expect {
          described_class.new.perform
        }.not_to raise_error
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Failed to send reminder to subscriber #{eligible_subscriber.id}/)

        described_class.new.perform
      end

      it 'reports the error to RorVsWild' do
        described_class.new.perform

        expect(RorVsWild).to have_received(:record_error).with(
          an_instance_of(StandardError),
          context: { subscriber_id: eligible_subscriber.id }
        )
      end

      it 'does not record reminder as sent when error occurs' do
        described_class.new.perform

        eligible_subscriber.reload
        expect(eligible_subscriber.reminder_sent?).to be false
      end

      it 'logs completion with error count' do
        expect(Rails.logger).to receive(:info).with(/Completed: 0 sent, 1 failed/)

        described_class.new.perform
      end
    end

    context 'when record_reminder_sent! fails' do
      before do
        allow_any_instance_of(Subscriber).to receive(:record_reminder_sent!).and_raise(StandardError.new("DB error"))
        allow(RorVsWild).to receive(:record_error)
      end

      it 'handles the error and logs it' do
        expect(Rails.logger).to receive(:error).with(/Failed to send reminder to subscriber #{eligible_subscriber.id}/)

        described_class.new.perform
      end

      it 'still sends the email before the error occurs' do
        expect {
          described_class.new.perform
        }.to have_enqueued_mail(SubscriptionMailer, :confirmation_reminder)
      end
    end

    context 'when no eligible subscribers exist' do
      before do
        eligible_subscriber.update!(status: 'verified')
      end

      it 'completes without errors' do
        expect {
          described_class.new.perform
        }.not_to raise_error
      end

      it 'logs zero subscribers processed' do
        expect(Rails.logger).to receive(:info).with(/Completed: 0 sent, 0 failed/)

        described_class.new.perform
      end
    end

    context 'concurrency safety' do
      it 'uses claim_for_reminder to ensure safe processing' do
        expect(Subscriber).to receive(:claim_for_reminder).with(eligible_subscriber.id).and_call_original

        described_class.new.perform
      end

      it 'handles case where subscriber becomes ineligible between query and processing' do
        # Simulate another process marking subscriber as verified after the initial query
        allow(Subscriber).to receive(:claim_for_reminder) do |id, &block|
          subscriber = Subscriber.find(id)
          subscriber.update!(status: 'verified') # Becomes ineligible
          subscriber.with_lock do
            block.call(subscriber) if subscriber.eligible_for_automatic_reminder? && block
          end
        end

        expect {
          described_class.new.perform
        }.not_to have_enqueued_mail(SubscriptionMailer, :confirmation_reminder)
      end
    end

    context 'with custom batch size from environment' do
      it 'uses default batch size when no environment variable is set' do
        expect(described_class::BATCH_SIZE).to eq(100)
      end
    end

    context 'when scheduling is disabled' do
      before do
        allow(AppConfig).to receive(:get).with("ENABLE_AUTO_REMINDERS", false).and_return(false)
      end

      it 'returns early without processing any subscribers' do
        expect(Subscriber).not_to receive(:eligible_for_reminder)
        expect {
          described_class.new.perform
        }.not_to have_enqueued_mail(SubscriptionMailer, :confirmation_reminder)
      end

      it 'does not log any processing information' do
        expect(Rails.logger).not_to receive(:info)
        described_class.new.perform
      end
    end
  end
end
