require 'rails_helper'

RSpec.describe CreateSubscriberJob, type: :job do
  let(:newsletter) { create(:newsletter) }
  let(:email) { 'test@example.com' }
  let(:name) { 'John Doe' }
  let(:labels) { 'label1,label2' }
  let(:created_via) { 'form' }
  let(:analytics_data) { { 'referrer' => 'homepage' } }
  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)

    # Create labels in the newsletter for the filter_invalid_labels callback
    [ 'label1', 'label2' ].each do |label_name|
      create(:label, newsletter: newsletter, name: label_name)
    end
  end

  describe '#perform' do
    context 'when email verification is successful' do
      before do
        allow(VerifyEmailService).to receive(:valid?).with(email).and_return(true)
      end

      context 'when subscriber does not exist' do
        it 'creates a new subscriber with provided information' do
          expect {
            described_class.perform_now(newsletter.id, email, name, labels, created_via, analytics_data)
          }.to change(Subscriber, :count).by(1)

          subscriber = Subscriber.last
          expect(subscriber.email).to eq(email)
          expect(subscriber.full_name).to eq(name)
          expect(subscriber.labels).to match_array([ 'label1', 'label2' ])
          expect(subscriber.created_via).to eq(created_via)
          expect(subscriber.analytics_data).to eq(analytics_data)
          expect(subscriber.newsletter_id).to eq(newsletter.id)
        end

        it 'logs information about the verification' do
          expect(Rails.logger).to receive(:info).with("[CreateSubscriberJob] Email verification for #{email}: true")
          described_class.perform_now(newsletter.id, email, name, labels, created_via, analytics_data)
        end
      end

      context 'when subscriber already exists' do
        let!(:existing_subscriber) { create(:subscriber, newsletter: newsletter, email: email) }

        it 'updates the existing subscriber' do
          expect {
            described_class.perform_now(newsletter.id, email, name, labels, created_via, analytics_data)
          }.not_to change(Subscriber, :count)

          existing_subscriber.reload
          expect(existing_subscriber.full_name).to eq(name)
          expect(existing_subscriber.labels).to match_array([ 'label1', 'label2' ])
          expect(existing_subscriber.created_via).to eq(created_via)
          expect(existing_subscriber.analytics_data).to eq(analytics_data)
        end

        context 'when subscriber is already verified' do
          let!(:existing_subscriber) do
            create(:subscriber, newsletter: newsletter, email: email, status: :verified, verified_at: 1.day.ago)
          end

          it 'does not send confirmation email' do
            expect_any_instance_of(Subscriber).not_to receive(:send_confirmation_email)
            described_class.perform_now(newsletter.id, email, name, labels, created_via, analytics_data)
          end
        end

        context 'when subscriber is not verified' do
          let!(:existing_subscriber) do
            create(:subscriber, newsletter: newsletter, email: email, status: :unverified)
          end

          it 'sends confirmation email' do
            expect_any_instance_of(Subscriber).to receive(:send_confirmation_email)
            described_class.perform_now(newsletter.id, email, name, labels, created_via, analytics_data)
          end
        end
      end

      context 'when no name is provided' do
        it 'does not update the name field' do
          existing_subscriber = create(:subscriber, newsletter: newsletter, email: email, full_name: 'Original Name')

          described_class.perform_now(newsletter.id, email, '', labels, created_via, analytics_data)

          expect(existing_subscriber.reload.full_name).to eq('Original Name')
        end
      end

      context 'when no labels are provided' do
        it 'sets labels to an empty array' do
          described_class.perform_now(newsletter.id, email, name, nil, created_via, analytics_data)

          expect(Subscriber.last.labels).to eq([])
        end
      end
    end

    context 'when email verification fails' do
      before do
        allow(VerifyEmailService).to receive(:valid?).with(email).and_return(false)
      end

      it 'does not create a subscriber' do
        expect {
          described_class.perform_now(newsletter.id, email, name, labels, created_via, analytics_data)
        }.not_to change(Subscriber, :count)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with("[CreateSubscriberJob] Invalid email or MX record for #{email}")
        described_class.perform_now(newsletter.id, email, name, labels, created_via, analytics_data)
      end
    end

    context 'when newsletter does not exist' do
      it 'raises an error' do
        expect {
          described_class.perform_now(999, email, name, labels, created_via, analytics_data)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
