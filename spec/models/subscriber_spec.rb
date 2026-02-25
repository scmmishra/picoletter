# == Schema Information
#
# Table name: subscribers
#
#  id                 :bigint           not null, primary key
#  analytics_data     :jsonb
#  created_via        :string
#  email              :string
#  full_name          :string
#  labels             :string           default([]), is an Array
#  notes              :text
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
#  index_subscribers_on_labels         (labels) USING gin
#  index_subscribers_on_newsletter_id  (newsletter_id)
#  index_subscribers_on_status         (status)
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

  describe '.eligible_for_auto_reminder' do
    it 'includes unverified subscribers created ~24 hours ago without reminders' do
      eligible = create(:subscriber, newsletter: newsletter, status: :unverified, created_at: 24.hours.ago)
      expect(Subscriber.eligible_for_auto_reminder).to include(eligible)
    end

    it 'excludes verified subscribers' do
      verified = create(:subscriber, newsletter: newsletter, status: :verified, created_at: 24.hours.ago)
      expect(Subscriber.eligible_for_auto_reminder).not_to include(verified)
    end

    it 'excludes subscribers with existing reminders' do
      with_reminder = create(:subscriber, newsletter: newsletter, status: :unverified, created_at: 24.hours.ago)
      create(:subscriber_reminder, subscriber: with_reminder, kind: :manual)
      expect(Subscriber.eligible_for_auto_reminder).not_to include(with_reminder)
    end

    it 'excludes subscribers created less than 23h15m ago' do
      too_recent = create(:subscriber, newsletter: newsletter, status: :unverified, created_at: 23.hours.ago)
      expect(Subscriber.eligible_for_auto_reminder).not_to include(too_recent)
    end

    it 'excludes subscribers created more than 24h45m ago' do
      too_old = create(:subscriber, newsletter: newsletter, status: :unverified, created_at: 25.hours.ago)
      expect(Subscriber.eligible_for_auto_reminder).not_to include(too_old)
    end

    it 'includes subscribers within the 45 minute margin' do
      within_margin = create(:subscriber, newsletter: newsletter, status: :unverified, created_at: 24.hours.ago + 30.minutes)
      expect(Subscriber.eligible_for_auto_reminder).to include(within_margin)
    end
  end

  describe '#has_delivery_issues?' do
    it 'returns true if subscriber has bounced emails' do
      sub = create(:subscriber, newsletter: newsletter)
      create(:email, subscriber: sub, status: :bounced)
      expect(sub.has_delivery_issues?).to be true
    end

    it 'returns true if subscriber has complained emails' do
      sub = create(:subscriber, newsletter: newsletter)
      create(:email, subscriber: sub, status: :complained)
      expect(sub.has_delivery_issues?).to be true
    end

    it 'returns false if subscriber has no delivery issues' do
      sub = create(:subscriber, newsletter: newsletter)
      create(:email, subscriber: sub, status: :delivered)
      expect(sub.has_delivery_issues?).to be false
    end

    it 'returns false if subscriber has no emails' do
      sub = create(:subscriber, newsletter: newsletter)
      expect(sub.has_delivery_issues?).to be false
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

  describe '#reminder_cooldown_active?' do
    it 'returns true if a reminder was sent within the last 24 hours' do
      sub = create(:subscriber, newsletter: newsletter, status: :unverified)
      create(:subscriber_reminder, subscriber: sub, kind: :manual, sent_at: 12.hours.ago)
      expect(sub.reminder_cooldown_active?).to be true
    end

    it 'returns false if no reminders have been sent' do
      sub = create(:subscriber, newsletter: newsletter, status: :unverified)
      expect(sub.reminder_cooldown_active?).to be false
    end

    it 'returns false if the last reminder was sent more than 24 hours ago' do
      sub = create(:subscriber, newsletter: newsletter, status: :unverified)
      create(:subscriber_reminder, subscriber: sub, kind: :manual, sent_at: 25.hours.ago)
      expect(sub.reminder_cooldown_active?).to be false
    end
  end

  describe 'email sending' do
    it 'sends confirmation email' do
      expect {
        subscriber.send_confirmation_email
      }.to have_enqueued_mail(SubscriptionMailer, :confirmation)
    end

    it 'sends reminder email via SendSubscriberReminderJob' do
      expect {
        subscriber.send_reminder
      }.to have_enqueued_job(SendSubscriberReminderJob).with(subscriber.id, kind: :manual)
    end

    it 'allows specifying the reminder kind' do
      expect {
        subscriber.send_reminder(kind: :automatic)
      }.to have_enqueued_job(SendSubscriberReminderJob).with(subscriber.id, kind: :automatic)
    end
  end
end
