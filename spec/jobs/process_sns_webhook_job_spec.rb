require 'rails_helper'

RSpec.describe ProcessSNSWebhookJob, type: :job do
  let(:email) { create(:email) }

  describe '#perform' do
    context 'when receiving SubscriptionConfirmation' do
      let(:payload) do
        {
          Type: 'SubscriptionConfirmation',
          SubscribeURL: 'https://sns.example.com/confirm'
        }
      end

      it 'calls process_subscription_confirmation' do
        expect(HTTParty).to receive(:get).with(payload[:SubscribeURL])
        described_class.perform_now(payload)
      end
    end

    context 'when receiving bounce notification' do
      let(:timestamp) { Time.current }
      let(:payload) do
        {
          Type: 'Notification',
          Message: {
            eventType: 'Bounce',
            mail: { messageId: email.id },
            bounce: { timestamp: timestamp }
          }.to_json
        }
      end

      it 'updates email status to bounced' do
        described_class.perform_now(payload)
        expect(email.reload.status).to eq('bounced')
        expect(email.bounced_at).to be_within(1.second).of(timestamp)
      end

      context 'when bounce count exceeds threshold' do
        before do
          create_list(:email, 2, subscriber: email.subscriber, status: :bounced)
        end

        it 'unsubscribes the subscriber' do
          expect {
            described_class.perform_now(payload)
          }.to change { email.subscriber.reload.status }.from('verified').to('unsubscribed')
        end
      end
    end

    context 'when receiving complaint notification' do
      let(:timestamp) { Time.current }
      let(:payload) do
        {
          Type: 'Notification',
          Message: {
            eventType: 'Complaint',
            mail: { messageId: email.id },
            complaint: { timestamp: timestamp }
          }.to_json
        }
      end

      it 'updates email status and unsubscribes the subscriber' do
        described_class.perform_now(payload)
        email.reload
        expect(email.status).to eq('complained')
        expect(email.complained_at).to be_within(1.second).of(timestamp)
        expect(email.subscriber.status).to eq('unsubscribed')
      end
    end

    context 'when receiving delivery notification' do
      let(:timestamp) { Time.current }
      let(:payload) do
        {
          Type: 'Notification',
          Message: {
            eventType: 'Delivery',
            mail: { messageId: email.id },
            delivery: { timestamp: timestamp }
          }.to_json
        }
      end

      it 'updates email status to delivered' do
        described_class.perform_now(payload)
        email.reload
        expect(email.status).to eq('delivered')
        expect(email.delivered_at).to be_within(1.second).of(timestamp)
      end
    end

    context 'when receiving click notification' do
      let(:timestamp) { Time.current }
      let(:link) { 'https://example.com' }
      let(:payload) do
        {
          Type: 'Notification',
          Message: {
            eventType: 'Click',
            mail: { messageId: email.id },
            click: {
              timestamp: timestamp,
              link: link
            }
          }.to_json
        }
      end

      it 'creates a click record' do
        expect {
          described_class.perform_now(payload)
        }.to change(EmailClick, :count).by(1)

        click = EmailClick.last
        expect(click.link).to eq(link)
        expect(click.timestamp).to be_within(1.second).of(timestamp)
        expect(click.post_id).to eq(email.post_id)
      end

      it 'does not create duplicate click records' do
        create(:email_click, email_id: email.id, link: link, post_id: email.post_id)

        expect {
          described_class.perform_now(payload)
        }.not_to change(EmailClick, :count)
      end
    end

    context 'when receiving open notification' do
      let(:timestamp) { Time.current }
      let(:payload) do
        {
          Type: 'Notification',
          Message: {
            eventType: 'Open',
            mail: { messageId: email.id },
            open: { timestamp: timestamp }
          }.to_json
        }
      end

      it 'updates email opened_at timestamp' do
        described_class.perform_now(payload)
        expect(email.reload.opened_at).to be_within(1.second).of(timestamp)
      end
    end

    context 'when email is not found' do
      let(:payload) do
        {
          Type: 'Notification',
          Message: {
            eventType: 'Open',
            mail: { messageId: 'non-existent-id' },
            open: { timestamp: Time.current }
          }.to_json
        }
      end

      it 'does not process the event' do
        expect {
          described_class.perform_now(payload)
        }.not_to change { email.reload.opened_at }
      end
    end
  end
end
