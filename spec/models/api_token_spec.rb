# == Schema Information
#
# Table name: api_tokens
#
#  id            :bigint           not null, primary key
#  permissions   :jsonb            not null
#  token         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  newsletter_id :bigint           not null
#
# Indexes
#
#  index_api_tokens_on_newsletter_id  (newsletter_id)
#  index_api_tokens_on_token          (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
require 'rails_helper'

RSpec.describe ApiToken, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:newsletter) }
  end

  describe 'validations' do
    subject { create(:api_token) }

    it { is_expected.to validate_presence_of(:token) }
    it { is_expected.to validate_uniqueness_of(:token) }
  end

  describe 'token generation' do
    it 'generates a token with pcltr_ prefix on create' do
      token = create(:api_token)
      expect(token.token).to start_with('pcltr_')
    end

    it 'does not overwrite an explicitly set token' do
      token = create(:api_token, token: 'pcltr_custom_token')
      expect(token.token).to eq('pcltr_custom_token')
    end
  end

  describe '#has_permission?' do
    let(:token) { create(:api_token, permissions: [ "subscription", "read" ]) }

    it 'returns true for a permission that exists' do
      expect(token.has_permission?("subscription")).to be true
    end

    it 'returns false for a permission that does not exist' do
      expect(token.has_permission?("admin")).to be false
    end

    it 'accepts symbols' do
      expect(token.has_permission?(:subscription)).to be true
    end
  end

  describe '#regenerate!' do
    it 'changes the token value' do
      token = create(:api_token)
      old_token = token.token
      token.regenerate!
      expect(token.token).not_to eq(old_token)
      expect(token.token).to start_with('pcltr_')
    end
  end
end
