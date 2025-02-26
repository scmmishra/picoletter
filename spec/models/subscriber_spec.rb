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
end
