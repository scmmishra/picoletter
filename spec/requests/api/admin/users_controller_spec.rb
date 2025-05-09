require 'rails_helper'

RSpec.describe Api::Admin::UsersController, type: :request do
  let(:user) { create(:user, email: 'test@example.com', active: true) }
  let(:api_key) { 'test_api_key' }
  let(:headers) do
    {
      'X-Api-Key' => api_key,
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
    allow(AppConfig).to receive(:get).and_call_original
    allow(AppConfig).to receive(:get).with('ENABLE_BILLING', false).and_return(true)
  end

  describe 'POST /api/admin/users/update_limits' do
    let(:endpoint) { '/api/admin/users/update_limits' }
    let(:params) do
      {
        id: user.id,
        limits: {
          subscriber_limit: 4000,
          monthly_email_limit: 20000
        },
        additional_data: {
          subscription: {
            amount: 1200,
            status: 'active',
            currency: 'usd',
            current_period_end: '2025-05-01T11:35:25.750Z',
            current_period_start: '2025-04-01T11:35:25.750Z'
          }
        }
      }
    end

    context 'with valid parameters and authentication' do
      before do
        post endpoint, params: params, headers: headers, as: :json
      end

      it 'returns a successful response' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['success']).to eq(true)
      end

      it 'updates the user limits' do
        user.reload
        expect(user.limits['subscriber_limit']).to eq(4000)
        expect(user.limits['monthly_email_limit']).to eq(20000)
      end

      it 'updates the additional data' do
        user.reload
        subscription = user.additional_data['subscription']
        expect(subscription['amount']).to eq(1200)
        expect(subscription['status']).to eq('active')
        expect(subscription['currency']).to eq('usd')
        expect(subscription['current_period_end']).to eq('2025-05-01T11:35:25.750Z')
        expect(subscription['current_period_start']).to eq('2025-04-01T11:35:25.750Z')
      end
    end

    context 'when billing is disabled' do
      before do
        allow(AppConfig).to receive(:get).with('ENABLE_BILLING', false).and_return(false)
        post endpoint, params: params, headers: headers, as: :json
      end

      it 'returns a forbidden response' do
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('API access is not enabled')
      end
    end

    context 'with invalid API key' do
      before do
        headers['X-Api-Key'] = 'invalid_key'
        post endpoint, params: params, headers: headers, as: :json
      end

      it 'returns an unauthorized response' do
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Unauthorized')
      end
    end

    context 'with non-existent user' do
      let(:nonexistent_params) do
        params.merge(id: 999999)
      end

      before do
        post endpoint, params: nonexistent_params, headers: headers, as: :json
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
        id: user.id,
        active: false
      }
    end

    context 'with valid parameters and authentication' do
      before do
        post endpoint, params: params, headers: headers, as: :json
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
          id: inactive_user.id,
          active: true
        }
      end

      before do
        post endpoint, params: reactivate_params, headers: headers, as: :json
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
          id: 999999,
          active: false
        }
      end

      before do
        post endpoint, params: nonexistent_params, headers: headers, as: :json
      end

      it 'returns a not found response' do
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['success']).to eq(false)
        expect(JSON.parse(response.body)['error']).to eq('User not found')
      end
    end
  end
end
