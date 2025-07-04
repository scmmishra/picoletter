# == Schema Information
#
# Table name: cohorts
#
#  id                :bigint           not null, primary key
#  color             :string
#  description       :text
#  filter_conditions :jsonb            not null
#  icon              :string
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
require 'rails_helper'

RSpec.describe Cohort, type: :model do
  let(:newsletter) { create(:newsletter) }
  let(:cohort) { create(:cohort, newsletter: newsletter) }

  subject { cohort }

  describe 'associations' do
    it { should belong_to(:newsletter) }
    it { should have_many(:posts).dependent(:nullify) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:filter_conditions) }
    it { should validate_uniqueness_of(:name).scoped_to(:newsletter_id) }
  end

  describe '#subscriber_count' do
    it 'returns the count of subscribers matching the cohort criteria' do
      expect(cohort.subscriber_count).to eq(0)
    end
  end

  describe '#subscribers' do
    it 'returns subscribers matching the cohort criteria' do
      expect(cohort.subscribers).to be_empty
    end
  end

  describe '#label_ids' do
    it 'returns label IDs from filter conditions' do
      cohort.filter_conditions = { "label_ids" => [ "1", "2" ] }
      expect(cohort.label_ids).to eq([ "1", "2" ])
    end
  end
end
