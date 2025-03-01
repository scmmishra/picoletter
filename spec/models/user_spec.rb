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
end
