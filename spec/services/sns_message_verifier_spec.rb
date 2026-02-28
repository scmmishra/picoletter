require 'rails_helper'

RSpec.describe SNSMessageVerifier do
  describe '#authentic?' do
    let(:private_key) { OpenSSL::PKey::RSA.new(2048) }
    let(:certificate) do
      OpenSSL::X509::Certificate.new.tap do |cert|
        cert.version = 2
        cert.serial = 1
        cert.subject = OpenSSL::X509::Name.parse('/CN=sns.amazonaws.com')
        cert.issuer = cert.subject
        cert.public_key = private_key.public_key
        cert.not_before = 1.day.ago
        cert.not_after = 1.day.from_now
        cert.sign(private_key, OpenSSL::Digest::SHA256.new)
      end
    end
    let(:base_payload) do
      {
        'Type' => 'Notification',
        'Message' => '{"eventType":"Delivery"}',
        'MessageId' => 'message-1',
        'Timestamp' => '2026-02-28T12:00:00.000Z',
        'TopicArn' => 'arn:aws:sns:us-east-1:123456789012:test',
        'SignatureVersion' => '2',
        'SigningCertURL' => 'https://sns.us-east-1.amazonaws.com/SimpleNotificationService-test.pem'
      }
    end
    let(:string_to_sign) do
      [
        "Message",
        '{"eventType":"Delivery"}',
        "MessageId",
        "message-1",
        "Timestamp",
        "2026-02-28T12:00:00.000Z",
        "TopicArn",
        "arn:aws:sns:us-east-1:123456789012:test",
        "Type",
        "Notification"
      ].join("\n") + "\n"
    end
    let(:signature) { Base64.strict_encode64(private_key.sign(OpenSSL::Digest::SHA256.new, string_to_sign)) }
    let(:payload) { base_payload.merge('Signature' => signature) }
    subject(:verifier) { described_class.new(payload) }

    before do
      allow(verifier).to receive(:fetch_signing_certificate).and_return(certificate)
    end

    it 'returns true for a valid signed payload' do
      expect(verifier.authentic?).to be(true)
    end

    context 'when the payload is tampered with' do
      let(:payload) { base_payload.merge('Signature' => signature, 'Message' => '{"eventType":"Bounce"}') }

      it 'returns false' do
        expect(verifier.authentic?).to be(false)
      end
    end

    context 'when SignatureVersion is unsupported' do
      let(:payload) { base_payload.merge('Signature' => signature, 'SignatureVersion' => '3') }

      it 'returns false' do
        expect(verifier.authentic?).to be(false)
      end
    end
  end

  describe '.valid_signing_cert_url?' do
    it 'accepts AWS SNS certificate URLs' do
      url = 'https://sns.us-east-1.amazonaws.com/SimpleNotificationService-test.pem'
      expect(described_class.valid_signing_cert_url?(url)).to be(true)
    end

    it 'rejects non-AWS certificate URLs' do
      url = 'https://example.com/SimpleNotificationService-test.pem'
      expect(described_class.valid_signing_cert_url?(url)).to be(false)
    end
  end

  describe '.valid_subscription_confirmation_url?' do
    it 'accepts valid AWS SNS confirmation URLs' do
      url = 'https://sns.us-east-1.amazonaws.com/?Action=ConfirmSubscription&Token=abc&TopicArn=arn:aws:sns:us-east-1:123456789012:test'
      expect(described_class.valid_subscription_confirmation_url?(url)).to be(true)
    end

    it 'rejects non-HTTPS URLs' do
      url = 'http://sns.us-east-1.amazonaws.com/?Action=ConfirmSubscription&Token=abc&TopicArn=arn:aws:sns:us-east-1:123456789012:test'
      expect(described_class.valid_subscription_confirmation_url?(url)).to be(false)
    end

    it 'rejects URLs that are not SNS confirmation actions' do
      url = 'https://sns.us-east-1.amazonaws.com/?Action=Publish&Token=abc&TopicArn=arn:aws:sns:us-east-1:123456789012:test'
      expect(described_class.valid_subscription_confirmation_url?(url)).to be(false)
    end
  end
end
