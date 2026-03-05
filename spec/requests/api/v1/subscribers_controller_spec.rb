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

  def parsed_body
    JSON.parse(response.body)
  end

  describe 'GET /api/v1/subscribers' do
    let(:endpoint) { '/api/v1/subscribers' }
    let!(:vip_label) { create(:label, newsletter: newsletter, name: 'vip') }
    let!(:newsletter_subscribers) do
      [
        create(:subscriber, newsletter: newsletter, email: 'oldest@example.com', status: :verified, labels: [ 'vip' ], created_at: 3.days.ago),
        create(:subscriber, newsletter: newsletter, email: 'middle@example.com', status: :unverified, labels: [ 'vip' ], created_at: 2.days.ago),
        create(:subscriber, newsletter: newsletter, email: 'latest@example.com', status: :unsubscribed, created_at: 1.day.ago)
      ]
    end

    it 'returns paginated subscribers ordered by created_at desc' do
      get endpoint, params: { page: 1, per_page: 2 }, headers: headers

      expect(response).to conform_schema(200)
      expect(parsed_body['data'].length).to eq(2)
      expect(parsed_body['data'].map { |subscriber| subscriber['email'] }).to eq([ 'latest@example.com', 'middle@example.com' ])
      expect(parsed_body['meta']).to eq({
        'page' => 1,
        'per_page' => 2,
        'total' => 3,
        'total_pages' => 2
      })
    end

    it 'filters by status' do
      get endpoint, params: { status: 'verified' }, headers: headers

      expect(response).to conform_schema(200)
      expect(parsed_body['data'].length).to eq(1)
      expect(parsed_body['data'].first['status']).to eq('verified')
    end

    it 'filters by label with case-insensitive matching' do
      get endpoint, params: { label: 'VIP' }, headers: headers

      expect(response).to conform_schema(200)
      expect(parsed_body['data'].length).to eq(2)
      expect(parsed_body['data'].map { |subscriber| subscriber['email'] }).to contain_exactly('oldest@example.com', 'middle@example.com')
    end

    it 'returns 422 for invalid status' do
      get endpoint, params: { status: 'bad' }, headers: headers

      expect(response).to conform_response_schema(422)
      expect(parsed_body['error']).to eq('Invalid status')
    end

    context 'with invalid token' do
      let(:headers) do
        {
          'Authorization' => 'Bearer invalid_token',
          'Content-Type' => 'application/json'
        }
      end

      it 'returns 401' do
        get endpoint, headers: headers

        expect(response).to conform_response_schema(401)
      end
    end

    context 'without authorization header' do
      let(:headers) { { 'Content-Type' => 'application/json' } }

      it 'returns 401' do
        get endpoint, headers: headers

        expect(response).to conform_response_schema(401)
      end
    end

    context 'when token lacks subscription permission' do
      let(:api_token) { create(:api_token, newsletter: newsletter, permissions: [ 'read' ]) }

      it 'returns 403' do
        get endpoint, headers: headers

        expect(response).to conform_response_schema(403)
        expect(parsed_body['error']).to eq('Insufficient permissions')
      end
    end
  end

  describe 'POST /api/v1/subscribers' do
    let(:endpoint) { '/api/v1/subscribers' }
    let(:params) { { email: 'subscriber@example.com', name: 'Test User' } }

    context 'with valid token and params' do
      it 'creates a subscriber and returns 201' do
        expect(CreateSubscriberJob).to receive(:perform_now)
          .with(newsletter.id, 'subscriber@example.com', 'Test User', nil, 'api', {})
          .and_return(true)

        post endpoint, params: params.to_json, headers: headers

        expect(response).to conform_schema(201)
        expect(parsed_body['email']).to eq('subscriber@example.com')
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
        expect(parsed_body['error']).to eq('Email is required')
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

    context 'with expired token' do
      let(:api_token) { create(:api_token, newsletter: newsletter, expires_at: 1.day.ago) }

      it 'returns 401' do
        post endpoint, params: params.to_json, headers: headers

        expect(response).to conform_response_schema(401)
        expect(parsed_body['error']).to eq('Unauthorized')
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
      let(:api_token) { create(:api_token, newsletter: newsletter, permissions: [ 'read' ]) }

      it 'returns 403' do
        post endpoint, params: params.to_json, headers: headers

        expect(response).to conform_response_schema(403)
        expect(parsed_body['error']).to eq('Insufficient permissions')
      end
    end
  end

  describe 'GET /api/v1/subscribers/:id' do
    let(:subscriber) { create(:subscriber, newsletter: newsletter, email: 'reader@example.com') }
    let(:endpoint) { "/api/v1/subscribers/#{subscriber.id}" }

    it 'returns subscriber details' do
      get endpoint, headers: headers

      expect(response).to conform_schema(200)
      expect(parsed_body['data']['id']).to eq(subscriber.id)
      expect(parsed_body['data']['email']).to eq('reader@example.com')
    end

    it 'returns 404 when subscriber is not found' do
      get '/api/v1/subscribers/999999', headers: headers

      expect(response).to conform_response_schema(404)
      expect(parsed_body['error']).to eq('Subscriber not found')
    end

    context 'with invalid token' do
      let(:headers) do
        {
          'Authorization' => 'Bearer invalid_token',
          'Content-Type' => 'application/json'
        }
      end

      it 'returns 401' do
        get endpoint, headers: headers

        expect(response).to conform_response_schema(401)
      end
    end

    context 'when token lacks subscription permission' do
      let(:api_token) { create(:api_token, newsletter: newsletter, permissions: [ 'read' ]) }

      it 'returns 403' do
        get endpoint, headers: headers

        expect(response).to conform_response_schema(403)
      end
    end
  end

  describe 'GET /api/v1/subscribers/lookup' do
    let!(:subscriber) { create(:subscriber, newsletter: newsletter, email: 'reader@example.com') }
    let(:endpoint) { '/api/v1/subscribers/lookup' }

    it 'finds a subscriber by email case-insensitively' do
      get endpoint, params: { email: 'READER@example.com' }, headers: headers

      expect(response).to conform_schema(200)
      expect(parsed_body['data']['id']).to eq(subscriber.id)
    end

    it 'returns 404 when lookup misses' do
      get endpoint, params: { email: 'missing@example.com' }, headers: headers

      expect(response).to conform_response_schema(404)
      expect(parsed_body['error']).to eq('Subscriber not found')
    end

    it 'returns 422 when email is missing' do
      get endpoint, headers: headers

      expect(response).to conform_response_schema(422)
      expect(parsed_body['error']).to eq('Email is required')
    end

    context 'with invalid token' do
      let(:headers) do
        {
          'Authorization' => 'Bearer invalid_token',
          'Content-Type' => 'application/json'
        }
      end

      it 'returns 401' do
        get endpoint, params: { email: 'reader@example.com' }, headers: headers

        expect(response).to conform_response_schema(401)
      end
    end

    context 'when token lacks subscription permission' do
      let(:api_token) { create(:api_token, newsletter: newsletter, permissions: [ 'read' ]) }

      it 'returns 403' do
        get endpoint, params: { email: 'reader@example.com' }, headers: headers

        expect(response).to conform_response_schema(403)
      end
    end
  end

  describe 'PATCH /api/v1/subscribers/:id' do
    let!(:vip_label) { create(:label, newsletter: newsletter, name: 'vip') }
    let(:subscriber) { create(:subscriber, newsletter: newsletter, email: 'reader@example.com') }
    let(:endpoint) { "/api/v1/subscribers/#{subscriber.id}" }

    it 'updates full_name, notes and labels' do
      patch endpoint, params: {
        full_name: 'Jane Reader',
        notes: 'Top subscriber',
        labels: [ 'VIP' ]
      }.to_json, headers: headers

      expect(response).to conform_schema(200)
      subscriber.reload
      expect(subscriber.full_name).to eq('Jane Reader')
      expect(subscriber.notes).to eq('Top subscriber')
      expect(subscriber.labels).to eq([ 'vip' ])
    end

    it 'returns 422 when no attributes are provided' do
      patch endpoint, params: {}.to_json, headers: headers

      expect(response).to conform_response_schema(422)
      expect(parsed_body['error']).to eq('At least one field is required')
    end

    it 'returns 404 when subscriber is not found' do
      patch '/api/v1/subscribers/999999', params: { notes: 'x' }.to_json, headers: headers

      expect(response).to conform_response_schema(404)
      expect(parsed_body['error']).to eq('Subscriber not found')
    end

    context 'with invalid token' do
      let(:headers) do
        {
          'Authorization' => 'Bearer invalid_token',
          'Content-Type' => 'application/json'
        }
      end

      it 'returns 401' do
        patch endpoint, params: { notes: 'x' }.to_json, headers: headers

        expect(response).to conform_response_schema(401)
      end
    end

    context 'when token lacks subscription permission' do
      let(:api_token) { create(:api_token, newsletter: newsletter, permissions: [ 'read' ]) }

      it 'returns 403' do
        patch endpoint, params: { notes: 'x' }.to_json, headers: headers

        expect(response).to conform_response_schema(403)
      end
    end
  end

  describe 'DELETE /api/v1/subscribers/:id' do
    let!(:subscriber) { create(:subscriber, newsletter: newsletter) }
    let(:endpoint) { "/api/v1/subscribers/#{subscriber.id}" }

    it 'deletes a subscriber and returns 204' do
      expect do
        delete endpoint, headers: headers
      end.to change(newsletter.subscribers, :count).by(-1)

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_blank
    end

    it 'returns 404 when subscriber is not found' do
      delete '/api/v1/subscribers/999999', headers: headers

      expect(response).to conform_response_schema(404)
      expect(parsed_body['error']).to eq('Subscriber not found')
    end

    context 'with invalid token' do
      let(:headers) do
        {
          'Authorization' => 'Bearer invalid_token',
          'Content-Type' => 'application/json'
        }
      end

      it 'returns 401' do
        delete endpoint, headers: headers

        expect(response).to conform_response_schema(401)
      end
    end

    context 'when token lacks subscription permission' do
      let(:api_token) { create(:api_token, newsletter: newsletter, permissions: [ 'read' ]) }

      it 'returns 403' do
        delete endpoint, headers: headers

        expect(response).to conform_response_schema(403)
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
        expect(parsed_body['total']).to eq(6)
        expect(parsed_body['verified']).to eq(3)
        expect(parsed_body['unverified']).to eq(2)
        expect(parsed_body['unsubscribed']).to eq(1)
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

    context 'with expired token' do
      let(:api_token) { create(:api_token, newsletter: newsletter, expires_at: 1.day.ago) }

      it 'returns 401' do
        get counts_endpoint, headers: headers

        expect(response).to conform_response_schema(401)
        expect(parsed_body['error']).to eq('Unauthorized')
      end
    end

    context 'when token lacks subscription permission' do
      let(:api_token) { create(:api_token, newsletter: newsletter, permissions: [ 'read' ]) }

      it 'returns 403' do
        get counts_endpoint, headers: headers

        expect(response).to conform_response_schema(403)
        expect(parsed_body['error']).to eq('Insufficient permissions')
      end
    end
  end
end
