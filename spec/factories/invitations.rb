# == Schema Information
#
# Table name: invitations
#
#  id            :bigint           not null, primary key
#  accepted_at   :datetime
#  email         :string           not null
#  expires_at    :datetime
#  role          :string           default("editor"), not null
#  token         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  invited_by_id :bigint           not null
#  newsletter_id :bigint           not null
#
# Indexes
#
#  index_invitations_on_invited_by_id            (invited_by_id)
#  index_invitations_on_newsletter_id            (newsletter_id)
#  index_invitations_on_newsletter_id_and_email  (newsletter_id,email) UNIQUE WHERE (accepted_at IS NULL)
#  index_invitations_on_token                    (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (invited_by_id => users.id)
#  fk_rails_...  (newsletter_id => newsletters.id)
#
FactoryBot.define do
  factory :invitation do
    newsletter { nil }
    email { "MyString" }
    role { "MyString" }
    token { "MyString" }
    invited_by { nil }
    accepted_at { "2025-08-08 21:59:41" }
    expires_at { "2025-08-08 21:59:41" }
  end
end
