# == Schema Information
#
# Table name: domains
#
#  id            :bigint           not null, primary key
#  dkim_status   :string           default("pending")
#  dmarc_added   :boolean          default(FALSE)
#  error_message :string
#  name          :string
#  public_key    :text
#  region        :string           default("us-east-1")
#  spf_status    :string           default("pending")
#  status        :string           default("pending")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  newsletter_id :bigint           not null
#
# Indexes
#
#  index_domains_on_name                                   (name) UNIQUE
#  index_domains_on_newsletter_id                          (newsletter_id)
#  index_domains_on_status_and_dkim_status_and_spf_status  (status,dkim_status,spf_status)
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
require 'rails_helper'

RSpec.describe Domain, type: :model do
  describe '#dkim_dns_value' do
    it 'returns nil when no public key is present' do
      domain = build(:domain, public_key: nil)

      expect(domain.dkim_dns_value).to be_nil
    end

    it 'returns a single TXT value for short keys' do
      public_key = 'a' * 216
      domain = build(:domain, public_key: public_key)

      expect(domain.dkim_dns_value).to eq("p=#{public_key}")
    end

    it 'splits long values into DNS-safe chunks' do
      public_key = 'a' * 392
      domain = build(:domain, public_key: public_key)

      formatted_value = domain.dkim_dns_value
      chunks = formatted_value.scan(/"([^"]+)"/).flatten

      expect(chunks).not_to be_empty
      expect(chunks).to all(satisfy { |chunk| chunk.length <= 255 })
      expect(chunks.join).to eq("p=#{public_key}")
    end
  end
end
