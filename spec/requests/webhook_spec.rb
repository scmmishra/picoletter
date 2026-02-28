require 'rails_helper'

RSpec.describe WebhookController do
  describe 'POST #sns' do
    let(:valid_payload) do
      {
        Type: 'Notification',
        Message: '{"eventType":"Delivery"}',
        MessageId: 'message-1',
        Timestamp: '2026-02-28T12:00:00.000Z',
        TopicArn: 'arn:aws:sns:us-east-1:123456789012:test',
        SignatureVersion: '2',
        Signature: 'signature',
        SigningCertURL: 'https://sns.us-east-1.amazonaws.com/SimpleNotificationService-test.pem'
      }.to_json
    end
    let(:verifier_result) { true }
    let(:verifier) { instance_double(SNSMessageVerifier, authentic?: verifier_result) }

    before do
      allow(SNSMessageVerifier).to receive(:new).and_return(verifier)
    end

    context 'with a verified SNS payload' do
      it 'enqueues ProcessSNSWebhookJob and returns no_content' do
        expect {
          post '/webhook/sns', params: valid_payload, headers: { 'CONTENT_TYPE': 'application/json' }
        }.to have_enqueued_job(ProcessSNSWebhookJob).with(JSON.parse(valid_payload))

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'with an unverified SNS payload' do
      let(:verifier_result) { false }

      it 'returns unauthorized and does not enqueue a job' do
        expect {
          post '/webhook/sns', params: valid_payload, headers: { 'CONTENT_TYPE': 'application/json' }
        }.not_to have_enqueued_job(ProcessSNSWebhookJob)

        expect(response).to have_http_status(:unauthorized)
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
