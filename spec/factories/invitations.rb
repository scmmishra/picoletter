# == Schema Information
#
# Table name: invitations
#
#  id            :bigint           not null, primary key
#  accepted_at   :datetime
#  email         :string           not null
#  role          :string           default("editor"), not null
#  token         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  invited_by_id :bigint           not null
#  newsletter_id :bigint           not null
#
# Indexes
#
#  index_invitations_on_invited_by_id  (invited_by_id)
#  index_invitations_on_newsletter_id  (newsletter_id)
#  index_invitations_on_token          (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (invited_by_id => users.id)
#  fk_rails_...  (newsletter_id => newsletters.id)
#
FactoryBot.define do
  factory :invitation do
    association :newsletter
    association :invited_by, factory: :user
    email { "invitee@example.com" }
    role { :editor }
    token { SecureRandom.urlsafe_base64(16) }
    accepted_at { nil }

    trait :accepted do
      accepted_at { Time.current }
    end

    trait :expired do
      created_at { Invitation::EXPIRATION_PERIOD.ago - 1.minute }
    end
  end
end
