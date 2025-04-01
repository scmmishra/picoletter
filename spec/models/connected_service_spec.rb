# == Schema Information
#
# Table name: connected_services
#
#  id         :bigint           not null, primary key
#  provider   :string           not null
#  uid        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_connected_services_on_provider_and_uid  (provider,uid) UNIQUE
#  index_connected_services_on_user_id           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe ConnectedService, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { create(:connected_service) }

    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:uid) }
    it { should validate_uniqueness_of(:provider).scoped_to(:uid) }
  end

  describe 'scopes' do
    let!(:google_service) { create(:connected_service, provider: 'google_oauth2') }
    let!(:github_service) { create(:connected_service, provider: 'github') }

    describe '.google' do
      it 'returns only google services' do
        expect(described_class.google).to include(google_service)
        expect(described_class.google).not_to include(github_service)
      end
    end

    describe '.github' do
      it 'returns only github services' do
        expect(described_class.github).to include(github_service)
        expect(described_class.github).not_to include(google_service)
      end
    end
  end

  describe '.find_or_create_from_auth_hash' do
    let(:user) { create(:user) }
    let(:auth_hash) do
      {
        'provider' => 'google_oauth2',
        'uid' => '123456',
        'info' => {
          'email' => 'test@example.com',
          'name' => 'Test User'
        }
      }
    end

    context 'when service already exists' do
      let!(:existing_service) do
        create(:connected_service, provider: auth_hash['provider'], uid: auth_hash['uid'], user: user)
      end

      it 'returns the existing service' do
        service = described_class.find_or_create_from_auth_hash(auth_hash)
        expect(service).to eq(existing_service)
      end
    end

    context 'when service does not exist' do
      context 'when user is provided' do
        it 'creates a new service with the given user' do
          service = described_class.find_or_create_from_auth_hash(auth_hash, user)
          
          expect(service).to be_persisted
          expect(service.provider).to eq(auth_hash['provider'])
          expect(service.uid).to eq(auth_hash['uid'])
          expect(service.user).to eq(user)
        end
      end

      context 'when user is not provided' do
        context 'when user exists with matching email' do
          let!(:existing_user) { create(:user, email: auth_hash['info']['email']) }

          it 'creates a new service with the existing user' do
            service = described_class.find_or_create_from_auth_hash(auth_hash)
            
            expect(service).to be_persisted
            expect(service.provider).to eq(auth_hash['provider'])
            expect(service.uid).to eq(auth_hash['uid'])
            expect(service.user).to eq(existing_user)
          end
        end

        context 'when no user exists with matching email' do
          it 'creates a new user and service' do
            expect {
              service = described_class.find_or_create_from_auth_hash(auth_hash)
              
              expect(service).to be_persisted
              expect(service.provider).to eq(auth_hash['provider'])
              expect(service.uid).to eq(auth_hash['uid'])
              expect(service.user.email).to eq(auth_hash['info']['email'])
              expect(service.user.name).to eq(auth_hash['info']['name'])
            }.to change(User, :count).by(1)
          end
        end
      end
    end
  end
end
