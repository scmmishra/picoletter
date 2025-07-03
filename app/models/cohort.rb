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
class Cohort < ApplicationRecord
  belongs_to :newsletter
  has_many :posts, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :newsletter_id }
  validates :filter_conditions, presence: true

  before_validation :set_default_filter_conditions
  before_save :update_filter_conditions

  def subscriber_count
    CohortQueryService.new(self).count
  end

  def subscribers
    CohortQueryService.new(self).call
  end

  def valid_rule?
    return false if filter_conditions.blank?

    # Test the rule with empty data to validate syntax
    JSONLogic.apply(filter_conditions, {})
    true
  rescue StandardError
    false
  end

  def test_rule(subscriber_data)
    return false if filter_conditions.blank?

    JSONLogic.apply(filter_conditions, subscriber_data)
  rescue StandardError
    false
  end

  private

  def set_default_filter_conditions
    self.filter_conditions ||= {}
  end
end
