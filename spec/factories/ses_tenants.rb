# == Schema Information
#
# Table name: ses_tenants
# Database name: primary
#
#  id              :bigint           not null, primary key
#  arn             :string
#  last_checked_at :datetime
#  last_error      :text
#  last_synced_at  :datetime
#  name            :string           not null
#  ready_at        :datetime
#  status          :string           default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  newsletter_id   :bigint           not null
#
# Indexes
#
#  index_ses_tenants_on_name           (name) UNIQUE
#  index_ses_tenants_on_newsletter_id  (newsletter_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
FactoryBot.define do
  factory :ses_tenant do
    association :newsletter
    sequence(:name) { |n| "picoletter-newsletter-#{n}" }
    arn { "arn:aws:ses:us-east-1:123456789012:tenant/#{name}" }
    status { :ready }
    last_checked_at { Time.current }
    last_synced_at { Time.current }
    ready_at { Time.current }

    trait :pending do
      status { :pending }
      ready_at { nil }
    end

    trait :failed do
      status { :failed }
      last_error { "Tenant preflight failed" }
    end
  end
end
