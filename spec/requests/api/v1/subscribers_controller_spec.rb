require 'rails_helper'

RSpec.describe Api::V1::SubscribersController, type: :request do
  let(:newsletter) { create(:newsletter) }
  let(:api_token) { create(:api_token, newsletter: newsletter) }
  let(:headers) do
    {
      'Authorization' => "Bearer #{api_token.token}",
      'Content-Type' => 'application/json'
    }
  end
  let(:endpoint) { '/api/v1/subscribers' }

  describe 'POST /api/v1/subscribers' do
    let(:params) { { email: 'subscriber@example.com', name: 'Test User' } }

    context 'with valid token and params' do
      it 'creates a subscriber and returns 201' do
        expect(CreateSubscriberJob).to receive(:perform_now)
          .with(newsletter.id, 'subscriber@example.com', 'Test User', nil, 'api', {})
          .and_return(true)

        post endpoint, params: params.to_json, headers: headers

        expect(response).to conform_schema(201)
        body = JSON.parse(response.body)
        expect(body['email']).to eq('subscriber@example.com')
      end
    end

    context 'with labels' do
      let(:params) { { email: 'subscriber@example.com', labels: 'vip,early-access' } }

      it 'passes labels to the job' do
        expect(CreateSubscriberJob).to receive(:perform_now)
          .with(newsletter.id, 'subscriber@example.com', nil, 'vip,early-access', 'api', {})
          .and_return(true)

        post endpoint, params: params.to_json, headers: headers

        expect(response).to conform_schema(201)
      end
    end

    context 'without email' do
      let(:params) { { name: 'Test User' } }

      it 'returns 422' do
        post endpoint, params: params.to_json, headers: headers

        expect(response).to conform_response_schema(422)
        body = JSON.parse(response.body)
        expect(body['error']).to eq('Email is required')
      end
    end

    context 'with invalid token' do
      let(:headers) do
        {
          'Authorization' => 'Bearer invalid_token',
          'Content-Type' => 'application/json'
        }
      end

      it 'returns 401' do
        post endpoint, params: params.to_json, headers: headers

        expect(response).to conform_response_schema(401)
      end
    end

    context 'without authorization header' do
      let(:headers) { { 'Content-Type' => 'application/json' } }

      it 'returns 401' do
        post endpoint, params: params.to_json, headers: headers

        expect(response).to conform_response_schema(401)
      end
    end

    context 'when token lacks subscription permission' do
      let(:api_token) { create(:api_token, newsletter: newsletter, permissions: [ "read" ]) }

      it 'returns 403' do
        post endpoint, params: params.to_json, headers: headers

        expect(response).to conform_response_schema(403)
        body = JSON.parse(response.body)
        expect(body['error']).to eq('Insufficient permissions')
      end
    end
  end

  describe 'GET /api/v1/subscribers/counts' do
    let(:counts_endpoint) { '/api/v1/subscribers/counts' }

    before do
      create_list(:subscriber, 3, newsletter: newsletter, status: :verified)
      create_list(:subscriber, 2, newsletter: newsletter, status: :unverified)
      create(:subscriber, newsletter: newsletter, status: :unsubscribed)
    end

    context 'with valid token' do
      it 'returns subscriber counts by status' do
        get counts_endpoint, headers: headers

        expect(response).to conform_schema(200)
        body = JSON.parse(response.body)
        expect(body['total']).to eq(6)
        expect(body['verified']).to eq(3)
        expect(body['unverified']).to eq(2)
        expect(body['unsubscribed']).to eq(1)
      end
    end

    context 'with invalid token' do
      let(:headers) do
        {
          'Authorization' => 'Bearer invalid_token',
          'Content-Type' => 'application/json'
        }
      end

      it 'returns 401' do
        get counts_endpoint, headers: headers

        expect(response).to conform_response_schema(401)
      end
    end
  end
end
