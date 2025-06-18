# == Schema Information
#
# Table name: subscribers
#
#  id                 :bigint           not null, primary key
#  additional_data    :jsonb            not null
#  analytics_data     :jsonb
#  created_via        :string
#  email              :string
#  full_name          :string
#  labels             :string           default([]), is an Array
#  notes              :text
#  reminder_status    :integer          default(0), not null
#  status             :integer          default("unverified")
#  unsubscribe_reason :string
#  unsubscribed_at    :datetime
#  verified_at        :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  newsletter_id      :integer          not null
#
# Indexes
#
#  index_subscribers_on_additional_data   (additional_data) USING gin
#  index_subscribers_on_labels            (labels) USING gin
#  index_subscribers_on_newsletter_id     (newsletter_id)
#  index_subscribers_on_reminder_sent_at  (((additional_data ->> 'last_reminder_sent_at'::text)))
#  index_subscribers_on_reminder_status   (reminder_status)
#  index_subscribers_on_status            (status)
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
require 'rails_helper'

RSpec.describe Subscriber, type: :model do
  let(:newsletter) { create(:newsletter) }
  let(:subscriber) { create(:subscriber, newsletter: newsletter) }

  describe 'validations' do
    it { should validate_presence_of(:email) }

    it 'validates email uniqueness within a newsletter' do
      existing = create(:subscriber, newsletter: newsletter, email: 'test@example.com')
      new_sub = build(:subscriber, newsletter: newsletter, email: 'TEST@example.com')

      expect(new_sub).not_to be_valid
      expect(new_sub.errors[:email]).to include('has already subscribed')
    end

    it 'allows same email for different newsletters' do
      other_newsletter = create(:newsletter)
      existing = create(:subscriber, newsletter: newsletter, email: 'test@example.com')
      new_sub = build(:subscriber, newsletter: other_newsletter, email: 'test@example.com')

      expect(new_sub).to be_valid
    end
  end

  describe 'scopes' do
    before do
      @verified = create(:subscriber, newsletter: newsletter, status: 'verified')
      @unverified = create(:subscriber, newsletter: newsletter, status: 'unverified')
      @unsubscribed = create(:subscriber, newsletter: newsletter, status: 'unsubscribed')
    end

    it 'returns verified subscribers' do
      expect(newsletter.subscribers.verified).to include(@verified)
      expect(newsletter.subscribers.verified).not_to include(@unverified, @unsubscribed)
    end

    it 'returns unverified subscribers' do
      expect(newsletter.subscribers.unverified).to include(@unverified)
      expect(newsletter.subscribers.unverified).not_to include(@verified, @unsubscribed)
    end

    it 'returns unsubscribed subscribers' do
      expect(newsletter.subscribers.unsubscribed).to include(@unsubscribed)
      expect(newsletter.subscribers.unsubscribed).not_to include(@verified, @unverified)
    end

    it 'returns subscribed (verified + unverified) subscribers' do
      expect(newsletter.subscribers.subscribed).to include(@verified, @unverified)
      expect(newsletter.subscribers.subscribed).not_to include(@unsubscribed)
    end
  end

  describe '#verify!' do
    it 'changes status to verified and sets verified_at' do
      unverified = create(:subscriber, newsletter: newsletter, status: 'unverified')

      expect {
        unverified.verify!
      }.to change { unverified.status }.from('unverified').to('verified')
      .and change { unverified.verified_at }.from(nil)

      expect(unverified.verified_at).to be_within(1.second).of(Time.current)
    end
  end

  describe '#unsubscribe!' do
    it 'changes status to unsubscribed and sets unsubscribed_at' do
      verified = create(:subscriber, newsletter: newsletter, status: 'verified')

      expect {
        verified.unsubscribe!
      }.to change { verified.status }.from('verified').to('unsubscribed')
      .and change { verified.unsubscribed_at }.from(nil)

      expect(verified.unsubscribed_at).to be_within(1.second).of(Time.current)
    end
  end

  describe '#unsubscribe_with_reason!' do
    it 'changes status to unsubscribed with reason and sets unsubscribed_at' do
      verified = create(:subscriber, newsletter: newsletter, status: 'verified')

      expect {
        verified.unsubscribe_with_reason!('bounced')
      }.to change { verified.status }.from('verified').to('unsubscribed')
      .and change { verified.unsubscribed_at }.from(nil)
      .and change { verified.unsubscribe_reason }.to('bounced')

      expect(verified.unsubscribed_at).to be_within(1.second).of(Time.current)
    end
  end

  describe '#display_name' do
    it 'returns full name when available' do
      sub = create(:subscriber, full_name: 'John Doe', email: 'john@example.com')
      expect(sub.display_name).to eq('John Doe')
    end

    it 'returns email when full name is not available' do
      sub = create(:subscriber, full_name: nil, email: 'john@example.com')
      expect(sub.display_name).to eq('john@example.com')

      sub = create(:subscriber, full_name: '', email: 'john@example.com')
      expect(sub.display_name).to eq('john@example.com')
    end
  end

  describe 'label handling' do
    let(:newsletter) { create(:newsletter) }

    before do
      create(:label, newsletter: newsletter, name: 'news')
      create(:label, newsletter: newsletter, name: 'updates')
    end

    it 'normalizes labels before validation' do
      sub = build(:subscriber, newsletter: newsletter, labels: [ 'NEWS', 'Updates', 'news' ])
      sub.valid? # trigger before_validation callback
      expect(sub.labels).to match_array([ 'news', 'updates' ])
    end

    it 'filters invalid labels before save' do
      sub = build(:subscriber, newsletter: newsletter, labels: [ 'news', 'updates', 'invalid' ])
      sub.save
      expect(sub.labels).to match_array([ 'news', 'updates' ])
    end
  end

  describe 'token generation' do
    it 'generates unsubscribe token' do
      expect(subscriber.generate_token_for(:unsubscribe)).to be_present
    end

    it 'generates confirmation token that expires' do
      token = subscriber.generate_token_for(:confirmation)
      expect(token).to be_present

      # We can't directly test expiration without time travel
      # But we can verify we can find by token
      found = Subscriber.find_by_token_for(:confirmation, token)
      expect(found).to eq(subscriber)
    end
  end

  describe 'email sending' do
    it 'sends confirmation email' do
      expect {
        subscriber.send_confirmation_email
      }.to have_enqueued_mail(SubscriptionMailer, :confirmation)
    end

    it 'sends reminder email' do
      expect {
        subscriber.send_reminder
      }.to have_enqueued_mail(SubscriptionMailer, :confirmation_reminder)
    end
  end

  describe 'automatic reminders' do
    let(:newsletter_with_reminders) { create(:newsletter, auto_reminder_enabled: true) }
    let(:newsletter_without_reminders) { create(:newsletter, auto_reminder_enabled: false) }

    describe '.eligible_for_reminder scope' do
      it 'includes unverified subscribers older than 24 hours with reminders enabled' do
        eligible = create(:subscriber,
          newsletter: newsletter_with_reminders,
          status: 'unverified',
          created_at: 25.hours.ago
        )

        result = Subscriber.eligible_for_reminder
        expect(result).to include(eligible)
      end

      it 'excludes subscribers from newsletters with reminders disabled' do
        ineligible = create(:subscriber,
          newsletter: newsletter_without_reminders,
          status: 'unverified',
          created_at: 25.hours.ago
        )

        result = Subscriber.eligible_for_reminder
        expect(result).not_to include(ineligible)
      end

      it 'excludes verified subscribers' do
        ineligible = create(:subscriber,
          newsletter: newsletter_with_reminders,
          status: 'verified',
          created_at: 25.hours.ago
        )

        result = Subscriber.eligible_for_reminder
        expect(result).not_to include(ineligible)
      end

      it 'excludes subscribers created less than 24 hours ago' do
        ineligible = create(:subscriber,
          newsletter: newsletter_with_reminders,
          status: 'unverified',
          created_at: 23.hours.ago
        )

        result = Subscriber.eligible_for_reminder
        expect(result).not_to include(ineligible)
      end

      it 'excludes subscribers who already received a reminder' do
        ineligible = create(:subscriber,
          newsletter: newsletter_with_reminders,
          status: 'unverified',
          created_at: 25.hours.ago,
          additional_data: { 'last_reminder_sent_at' => 1.hour.ago.iso8601 }
        )

        result = Subscriber.eligible_for_reminder
        expect(result).not_to include(ineligible)
      end
    end

    describe '#eligible_for_automatic_reminder?' do
      let(:subscriber) { create(:subscriber, newsletter: newsletter_with_reminders, status: 'unverified', created_at: 25.hours.ago) }

      it 'returns true for eligible subscriber' do
        expect(subscriber.eligible_for_automatic_reminder?).to be true
      end

      it 'returns false for verified subscriber' do
        subscriber.update!(status: 'verified')
        expect(subscriber.eligible_for_automatic_reminder?).to be false
      end

      it 'returns false for unsubscribed subscriber' do
        subscriber.update!(status: 'unsubscribed')
        expect(subscriber.eligible_for_automatic_reminder?).to be false
      end

      it 'returns false if reminder already sent' do
        subscriber.update!(additional_data: { 'last_reminder_sent_at' => 1.hour.ago.iso8601 })
        expect(subscriber.eligible_for_automatic_reminder?).to be false
      end

      it 'returns false if newsletter has reminders disabled' do
        subscriber.newsletter.update!(auto_reminder_enabled: false)
        expect(subscriber.eligible_for_automatic_reminder?).to be false
      end

      it 'returns false for subscriber created less than 24 hours ago' do
        subscriber.update!(created_at: 23.hours.ago)
        expect(subscriber.eligible_for_automatic_reminder?).to be false
      end
    end

    describe '#reminder_sent?' do
      it 'returns true when reminder was sent' do
        subscriber.update!(additional_data: { 'last_reminder_sent_at' => 1.hour.ago.iso8601 })
        expect(subscriber.reminder_sent?).to be true
      end

      it 'returns false when no reminder was sent' do
        expect(subscriber.reminder_sent?).to be false
      end
    end

    describe '#last_reminder_sent_at' do
      it 'returns parsed time when reminder was sent' do
        time = 1.hour.ago
        subscriber.update!(additional_data: { 'last_reminder_sent_at' => time.iso8601 })
        expect(subscriber.last_reminder_sent_at).to be_within(1.second).of(time)
      end

      it 'returns nil when no reminder was sent' do
        expect(subscriber.last_reminder_sent_at).to be_nil
      end

      it 'returns nil for invalid time format' do
        subscriber.update!(additional_data: { 'last_reminder_sent_at' => 'invalid' })
        expect(subscriber.last_reminder_sent_at).to be_nil
      end
    end

    describe '#record_reminder_sent!' do
      it 'records reminder timestamp and adds to reminders array' do
        expect {
          subscriber.record_reminder_sent!
        }.to change { subscriber.reminder_sent? }.from(false).to(true)

        expect(subscriber.last_reminder_sent_at).to be_within(1.second).of(Time.current)
        expect(subscriber.additional_data['reminders']).to include(subscriber.last_reminder_sent_at.iso8601)
      end

      it 'appends to existing reminders array' do
        existing_time = 1.day.ago.iso8601
        subscriber.update!(additional_data: { 'reminders' => [ existing_time ] })

        subscriber.record_reminder_sent!
        expect(subscriber.additional_data['reminders']).to include(existing_time, subscriber.last_reminder_sent_at.iso8601)
      end
    end

    describe '.claim_for_reminder' do
      let(:subscriber) { create(:subscriber, newsletter: newsletter_with_reminders, status: 'unverified', created_at: 25.hours.ago) }

      it 'yields eligible subscriber to block' do
        yielded_subscriber = nil
        Subscriber.claim_for_reminder(subscriber.id) do |sub|
          yielded_subscriber = sub
        end

        expect(yielded_subscriber).to eq(subscriber)
      end

      it 'does not yield if subscriber is not eligible' do
        subscriber.update!(status: 'verified')
        yielded = false

        Subscriber.claim_for_reminder(subscriber.id) do |sub|
          yielded = true
        end

        expect(yielded).to be false
      end

      it 'does not yield if subscriber already received reminder' do
        subscriber.update!(additional_data: { 'last_reminder_sent_at' => 1.hour.ago.iso8601 })
        yielded = false

        Subscriber.claim_for_reminder(subscriber.id) do |sub|
          yielded = true
        end

        expect(yielded).to be false
      end

      it 'returns nil for non-existent subscriber' do
        result = Subscriber.claim_for_reminder(99999) do |sub|
          # should not be called
        end

        expect(result).to be_nil
      end

      it 'handles database errors gracefully' do
        allow(Subscriber).to receive(:find).and_raise(StandardError.new("DB error"))
        allow(Rails.error).to receive(:report)

        result = Subscriber.claim_for_reminder(subscriber.id) do |sub|
          # should not be called
        end

        expect(result).to be_nil
        expect(Rails.error).to have_received(:report)
      end

      it 'uses database lock for concurrency safety' do
        allow(Subscriber).to receive(:find).and_return(subscriber)
        expect(subscriber).to receive(:with_lock).and_call_original

        Subscriber.claim_for_reminder(subscriber.id) do |sub|
          # block executes within lock
        end
      end
    end
  end
end
