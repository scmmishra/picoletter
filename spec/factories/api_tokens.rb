# == Schema Information
#
# Table name: api_tokens
#
#  id            :bigint           not null, primary key
#  expires_at    :datetime
#  permissions   :jsonb            not null
#  token         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  newsletter_id :bigint           not null
#
# Indexes
#
#  index_api_tokens_on_newsletter_id  (newsletter_id) UNIQUE
#  index_api_tokens_on_token          (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
FactoryBot.define do
  factory :api_token do
    newsletter
    permissions { [ "subscription" ] }
  end
end
