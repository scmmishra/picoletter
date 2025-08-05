# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  active          :boolean
#  additional_data :jsonb
#  bio             :text
#  email           :string           not null
#  is_superadmin   :boolean          default(FALSE)
#  limits          :jsonb
#  name            :string
#  password_digest :string
#  verified_at     :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_is_superadmin  (is_superadmin)
#
require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  before do
    allow(AppConfig).to receive(:get).and_call_original
  end

  describe 'verification methods' do
    describe '#verify!' do
      it 'updates verified_at timestamp' do
        expect { user.verify! }.to change { user.verified_at }.from(nil)
      end
    end

    describe '#verified?' do
      context 'when verification is enabled' do
        before do
          allow(AppConfig).to receive(:get).with("VERIFY_SIGNUPS", true).and_return(true)
        end

        it 'returns false when user is not verified' do
          expect(user.verified?).to be false
        end

        it 'returns true when user is verified' do
          user.verify!
          expect(user.verified?).to be true
        end
      end

      context 'when verification is disabled' do
        before do
          allow(AppConfig).to receive(:get).with("VERIFY_SIGNUPS", true).and_return(false)
        end

        it 'returns true regardless of verification status' do
          expect(user.verified?).to be true
        end
      end
    end

    describe '#send_verification_email' do
      it 'enqueues a verification email' do
        expect {
          user.send_verification_email
        }.to have_enqueued_mail(UserMailer, :verify_email)
      end
    end

    describe '#send_verification_email_once' do
      it 'sends email only once within the cache period' do
        expect(Rails.cache).to receive(:fetch).with("verification_email_#{user.id}").and_return(nil)
        expect(Rails.cache).to receive(:write).with("verification_email_#{user.id}", expires_in: 6.hours)

        expect {
          user.send_verification_email_once
        }.to have_enqueued_mail(UserMailer, :verify_email)

        allow(Rails.cache).to receive(:fetch).with("verification_email_#{user.id}").and_return(true)

        # Second call shouldn't send email
        expect {
          user.send_verification_email_once
        }.not_to have_enqueued_mail(UserMailer, :verify_email)
      end

      it 'does not send email if already sent within cache period' do
        allow(Rails.cache).to receive(:fetch).with("verification_email_#{user.id}").and_return(true)

        expect {
          user.send_verification_email_once
        }.not_to have_enqueued_mail(UserMailer, :verify_email)
      end
    end
  end

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:bio).is_at_most(500) }

    it 'validates email uniqueness case-insensitively' do
      existing = create(:user, email: 'test@example.com')
      new_user = build(:user, email: 'TEST@example.com')

      expect(new_user).not_to be_valid
      expect(new_user.errors[:email]).to include('has already been taken')
    end

    it 'validates email format' do
      user.email = 'invalid-email'
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end
  end

  describe 'associations' do
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:newsletters).dependent(:destroy) }
    it { should have_many(:subscribers).through(:newsletters) }
    it { should have_many(:posts).through(:newsletters) }
    it { should have_many(:emails).through(:posts) }
  end

  describe 'scopes' do
    it 'returns only active users' do
      active_user = create(:user, active: true)
      inactive_user = create(:user, active: false)

      expect(User.active).to include(active_user)
      expect(User.active).not_to include(inactive_user)
    end
  end

  describe 'callbacks' do
    it 'activates user on create' do
      user = build(:user, active: nil)
      user.save
      expect(user.active).to be true
    end

    it 'initializes additional_data on create' do
      user = build(:user, additional_data: nil)
      user.save
      expect(user.additional_data).to eq({})
    end
  end

  describe '#subscription' do
    it 'returns empty hash when additional_data is nil' do
      user.additional_data = nil
      expect(user.subscription).to eq({})
    end

    it 'returns subscription data with indifferent access' do
      user.additional_data = { 'subscription' => { 'plan' => 'pro' } }
      expect(user.subscription[:plan]).to eq('pro')
      expect(user.subscription['plan']).to eq('pro')
    end

    it 'returns empty hash when subscription data is not present' do
      user.additional_data = { 'other_data' => 'value' }
      expect(user.subscription).to eq({})
    end
  end

  describe '#super?' do
    it 'returns false for regular users' do
      expect(user.super?).to be false
    end

    it 'returns true for superadmins' do
      user.update(is_superadmin: true)
      expect(user.super?).to be true
    end
  end

  describe '#activate_user' do
    it 'sets active to true when nil' do
      new_user = build(:user, active: nil)
      new_user.save
      expect(new_user.active).to be true
    end

    it 'does not change active status when already set' do
      new_user = build(:user, active: false)
      new_user.save
      expect(new_user.active).to be false
    end
  end

  describe 'membership associations' do
    it { should have_many(:memberships) }
    it { should have_many(:newsletters).through(:memberships) }
  end

  describe '#newsletter_role' do
    let(:newsletter) { create(:newsletter, user: user) }
    let(:other_user) { create(:user) }

    it 'returns :owner for owned newsletters' do
      expect(user.newsletter_role(newsletter)).to eq(:owner)
    end

    it 'returns the membership role for member newsletters' do
      membership = create(:membership, user: other_user, newsletter: newsletter, role: :editor)
      expect(other_user.newsletter_role(newsletter)).to eq(:editor)
    end

    it 'returns nil for newsletters without access' do
      expect(other_user.newsletter_role(newsletter)).to be_nil
    end
  end

  describe 'newsletters association' do
    let!(:owned_newsletter) { create(:newsletter, user: user) }
    let!(:member_newsletter) { create(:newsletter) }
    let!(:membership) { create(:membership, user: user, newsletter: member_newsletter, role: :editor) }

    it 'includes newsletters where user has memberships' do
      expect(user.newsletters).to include(member_newsletter)
    end

    it 'includes owned newsletters after membership creation callback' do
      # The callback should create a membership for the owner
      expect(user.newsletters).to include(owned_newsletter)
    end
  end
end
