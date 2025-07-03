# == Schema Information
#
# Table name: cohorts
#
#  id                :bigint           not null, primary key
#  description       :text
#  emoji             :string
#  filter_conditions :jsonb            not null
#  name              :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  newsletter_id     :bigint           not null
#
# Indexes
#
#  index_cohorts_on_filter_conditions       (filter_conditions) USING gin
#  index_cohorts_on_newsletter_id           (newsletter_id)
#  index_cohorts_on_newsletter_id_and_name  (newsletter_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
FactoryBot.define do
  factory :cohort do
    sequence(:name) { |n| "Cohort #{n}" }
    description { "A test cohort for segmenting subscribers" }
    emoji { "👥" }
    filter_conditions { { "label_ids" => [] } }
    association :newsletter
  end
end
