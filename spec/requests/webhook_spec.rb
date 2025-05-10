require 'rails_helper'

RSpec.describe WebhookController do
  describe 'POST #sns' do
    let(:valid_payload) do
      {
        Type: 'Notification',
        Message: 'Test message',
        TopicArn: 'arn:aws:sns:test'
      }.to_json
    end

    context 'with valid JSON payload' do
      it 'enqueues ProcessSNSWebhookJob and returns no_content' do
        expect {
          post '/webhook/sns', params: valid_payload, headers: { 'CONTENT_TYPE': 'application/json' }
        }.to have_enqueued_job(ProcessSNSWebhookJob).with(JSON.parse(valid_payload))

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'with invalid JSON payload' do
      it 'returns bad_request status' do
        expect(RorVsWild).to receive(:record_error)

        post '/webhook/sns', params: '{invalid_json', headers: { 'CONTENT_TYPE': 'application/json' }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when an unexpected error occurs' do
      before do
        allow(ProcessSNSWebhookJob).to receive(:perform_later).and_raise(StandardError.new('Test error'))
      end

      it 'returns bad_request status and records the error' do
        expect(RorVsWild).to receive(:record_error)

        post '/webhook/sns', params: valid_payload, headers: { 'CONTENT_TYPE': 'application/json' }

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end