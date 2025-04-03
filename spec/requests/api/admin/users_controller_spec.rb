require 'rails_helper'

RSpec.describe Api::Admin::UsersController, type: :request do
  let!(:user) { create(:user, email: 'test@example.com', active: true) }
  let(:api_key) { 'test_api_key' }
  let(:hmac_secret) { 'test_hmac_secret' }
  let(:timestamp) { Time.current.to_i.to_s }
  let(:headers) do
    {
      'X-API-Key' => api_key,
      'Content-Type' => 'application/json'
    }
  end

  before do
    # Set default limits for the user
    user.update(limits: {
      'subscriber_limit' => 1000,
      'monthly_email_limit' => 10000
    })

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ADMIN_API_KEY').and_return(api_key)
    allow(ENV).to receive(:[]).with('ADMIN_API_HMAC_SECRET').and_return(hmac_secret)
    allow(AppConfig).to receive(:get).and_call_original
    allow(AppConfig).to receive(:get).with('ENABLE_BILLING', false).and_return(true)
  end

  describe 'POST /api/admin/users/update_limits' do
    let(:endpoint) { '/api/admin/users/update_limits' }
    let(:params) do
      {
        user_id: user.id,
        limits: {
          subscriber_limit: 5000,
          monthly_email_limit: 50000
        },
        additional_data: {
          subscription: {
            plan: 'premium',
            expires_at: '2025-12-31'
          }
        }
      }
    end
    let(:payload) { params.to_json }
    let(:signature_data) { "#{timestamp}:#{payload}" }
    let(:signature) { OpenSSL::HMAC.hexdigest('SHA256', hmac_secret, signature_data) }

    context 'with valid parameters and authentication' do
      before do
        headers['X-HMAC-Timestamp'] = timestamp
        headers['X-HMAC-Signature'] = signature
        post endpoint, params: payload, headers: headers, as: :json
      end

      it 'returns a successful response' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['success']).to eq(true)
      end

      it 'updates the user limits' do
        user.reload
        expect(user.limits['subscriber_limit']).to eq(5000)
        expect(user.limits['monthly_email_limit']).to eq(50000)
      end

      it 'updates the additional data' do
        user.reload
        expect(user.additional_data).not_to be_nil
        expect(user.additional_data['subscription']['plan']).to eq('premium')
        expect(user.additional_data['subscription']['expires_at']).to eq('2025-12-31')
      end
    end

    context 'when billing is disabled' do
      before do
        allow(AppConfig).to receive(:get).with('ENABLE_BILLING', false).and_return(false)
        headers['X-HMAC-Timestamp'] = timestamp
        headers['X-HMAC-Signature'] = signature
        post endpoint, params: payload, headers: headers, as: :json
      end

      it 'returns a forbidden response' do
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('API access is not enabled')
      end
    end

    context 'with invalid API key' do
      before do
        headers['X-API-Key'] = 'invalid_key'
        headers['X-HMAC-Timestamp'] = timestamp
        headers['X-HMAC-Signature'] = signature
        post endpoint, params: payload, headers: headers, as: :json
      end

      it 'returns an unauthorized response' do
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Unauthorized')
      end
    end

    context 'with invalid HMAC signature' do
      before do
        headers['X-HMAC-Timestamp'] = timestamp
        headers['X-HMAC-Signature'] = 'invalid_signature'
        post endpoint, params: payload, headers: headers, as: :json
      end

      it 'returns an unauthorized response' do
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid signature')
      end
    end

    context 'with expired timestamp' do
      before do
        headers['X-HMAC-Timestamp'] = (Time.current - 10.minutes).to_i.to_s
        headers['X-HMAC-Signature'] = OpenSSL::HMAC.hexdigest('SHA256', hmac_secret, "#{headers['X-HMAC-Timestamp']}:#{payload}")
        post endpoint, params: payload, headers: headers, as: :json
      end

      it 'returns an unauthorized response' do
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Request expired')
      end
    end

    context 'with non-existent user' do
      let(:nonexistent_params) do
        {
          user_id: 999999,
          limits: {
            subscriber_limit: 5000,
            monthly_email_limit: 50000
          }
        }
      end
      let(:nonexistent_payload) { nonexistent_params.to_json }
      let(:nonexistent_signature_data) { "#{timestamp}:#{nonexistent_payload}" }
      let(:nonexistent_signature) { OpenSSL::HMAC.hexdigest('SHA256', hmac_secret, nonexistent_signature_data) }

      before do
        headers['X-HMAC-Timestamp'] = timestamp
        headers['X-HMAC-Signature'] = nonexistent_signature
        post endpoint, params: nonexistent_payload, headers: headers, as: :json
      end

      it 'returns a not found response' do
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['success']).to eq(false)
        expect(JSON.parse(response.body)['error']).to eq('User not found')
      end
    end
  end

  describe 'POST /api/admin/users/toggle_active' do
    let(:endpoint) { '/api/admin/users/toggle_active' }
    let(:params) do
      {
        user_id: user.id,
        active: false
      }
    end
    let(:payload) { params.to_json }
    let(:signature_data) { "#{timestamp}:#{payload}" }
    let(:signature) { OpenSSL::HMAC.hexdigest('SHA256', hmac_secret, signature_data) }

    context 'with valid parameters and authentication' do
      before do
        headers['X-HMAC-Timestamp'] = timestamp
        headers['X-HMAC-Signature'] = signature
        post endpoint, params: payload, headers: headers, as: :json
      end

      it 'returns a successful response' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['success']).to eq(true)
      end

      it 'updates the user active status' do
        user.reload
        expect(user.active).to eq(false)
      end
    end

    context 'when reactivating a user' do
      let(:inactive_user) { create(:user, email: 'inactive@example.com', active: false) }
      let(:reactivate_params) do
        {
          user_id: inactive_user.id,
          active: true
        }
      end
      let(:reactivate_payload) { reactivate_params.to_json }
      let(:reactivate_signature_data) { "#{timestamp}:#{reactivate_payload}" }
      let(:reactivate_signature) { OpenSSL::HMAC.hexdigest('SHA256', hmac_secret, reactivate_signature_data) }

      before do
        headers['X-HMAC-Timestamp'] = timestamp
        headers['X-HMAC-Signature'] = reactivate_signature
        post endpoint, params: reactivate_payload, headers: headers, as: :json
      end

      it 'returns a successful response' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['success']).to eq(true)
      end

      it 'updates the user active status to true' do
        inactive_user.reload
        expect(inactive_user.active).to eq(true)
      end
    end

    context 'with non-existent user' do
      let(:nonexistent_params) do
        {
          user_id: 999999,
          active: false
        }
      end
      let(:nonexistent_payload) { nonexistent_params.to_json }
      let(:nonexistent_signature_data) { "#{timestamp}:#{nonexistent_payload}" }
      let(:nonexistent_signature) { OpenSSL::HMAC.hexdigest('SHA256', hmac_secret, nonexistent_signature_data) }

      before do
        headers['X-HMAC-Timestamp'] = timestamp
        headers['X-HMAC-Signature'] = nonexistent_signature
        post endpoint, params: nonexistent_payload, headers: headers, as: :json
      end

      it 'returns a not found response' do
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['success']).to eq(false)
        expect(JSON.parse(response.body)['error']).to eq('User not found')
      end
    end
  end
end
