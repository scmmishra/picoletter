require 'rails_helper'

RSpec.describe CohortQueryService do
  let(:newsletter) { create(:newsletter) }
  let(:label1) { create(:label, newsletter: newsletter, name: "premium") }
  let(:label2) { create(:label, newsletter: newsletter, name: "vip") }

  let(:cohort) do
    create(:cohort,
           newsletter: newsletter,
           filter_conditions: { "label_ids" => [ label1.id.to_s, label2.id.to_s ] })
  end

  let!(:subscriber1) do
    create(:subscriber, newsletter: newsletter, labels: [ label1.name, label2.name ], status: :verified)
  end

  let!(:subscriber2) do
    create(:subscriber, newsletter: newsletter, labels: [ label1.name ], status: :verified)
  end

  let!(:subscriber3) do
    create(:subscriber, newsletter: newsletter, labels: [], status: :verified)
  end

  describe '#call' do
    it 'returns subscribers with ALL specified labels (AND condition)' do
      result = described_class.new(cohort).call
      expect(result).to include(subscriber1)
      expect(result).not_to include(subscriber2, subscriber3)
    end

    it 'returns all verified subscribers when no filter conditions' do
      cohort.filter_conditions = {}
      result = described_class.new(cohort).call
      expect(result).to include(subscriber1, subscriber2, subscriber3)
    end
  end

  describe '#count' do
    it 'returns the count of matching subscribers' do
      expect(described_class.new(cohort).count).to eq(1)
    end
  end
end
