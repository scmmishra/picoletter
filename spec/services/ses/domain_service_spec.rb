require 'rails_helper'

RSpec.describe SES::DomainService do
  describe '#generate_key_pair' do
    let(:service) { described_class.allocate }

    it 'generates a 2048-bit RSA key pair' do
      private_key, public_key = service.send(:generate_key_pair)
      private_rsa_key = OpenSSL::PKey::RSA.new(pem_private_key(private_key))

      expect(private_rsa_key.n.num_bits).to eq(2048)
      expect(public_key).to eq(base64_public_key(private_rsa_key.public_key.to_pem))
    end

    it 'produces a public key value long enough to require DNS chunking' do
      _, public_key = service.send(:generate_key_pair)

      expect(public_key.length).to be > 255
    end

    def pem_private_key(base64_key)
      <<~PEM
        -----BEGIN RSA PRIVATE KEY-----
        #{base64_key.scan(/.{1,64}/).join("\n")}
        -----END RSA PRIVATE KEY-----
      PEM
    end

    def base64_public_key(public_pem)
      public_pem
        .gsub('-----BEGIN PUBLIC KEY-----', '')
        .gsub('-----END PUBLIC KEY-----', '')
        .gsub("\n", '')
    end
  end
end
