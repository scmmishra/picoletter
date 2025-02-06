# == Schema Information
#
# Table name: labels
#
#  id            :bigint           not null, primary key
#  color         :string           default("#6B7280"), not null
#  description   :text
#  name          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  newsletter_id :bigint           not null
#
# Indexes
#
#  index_labels_on_newsletter_id           (newsletter_id)
#  index_labels_on_newsletter_id_and_name  (newsletter_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
require 'rails_helper'

RSpec.describe Label, type: :model do
  describe 'associations' do
    it 'belongs to a newsletter' do
      label = build(:label)
      expect(label.newsletter).to be_present
    end
  end

  describe 'validations' do
    let(:newsletter) { create(:newsletter) }
    let(:label) { build(:label, newsletter: newsletter) }

    it 'is valid with valid attributes' do
      expect(label).to be_valid
    end

    it 'requires a name' do
      label.name = nil
      expect(label).not_to be_valid
      expect(label.errors[:name]).to include("can't be blank")
    end

    it 'requires a color' do
      label.color = nil
      expect(label).not_to be_valid
      expect(label.errors[:color]).to include("can't be blank")
    end

    it 'requires a unique name within the scope of a newsletter' do
      create(:label, name: 'test-label', newsletter: newsletter)
      new_label = build(:label, name: 'test-label', newsletter: newsletter)
      expect(new_label).not_to be_valid
      expect(new_label.errors[:name]).to include('has already been taken')
    end

    context 'color format' do
      it 'is valid with a proper hex color' do
        label.color = '#123ABC'
        expect(label).to be_valid
      end

      it 'is valid with a 3-digit hex color' do
        label.color = '#ABC'
        expect(label).to be_valid
      end

      it 'is invalid with an improper hex color' do
        label.color = 'invalid'
        expect(label).not_to be_valid
        expect(label.errors[:color]).to include('must be a valid hex color code')
      end
    end

    context 'name format' do
      it 'is valid with kebab-case format' do
        label.name = 'my-label-1'
        expect(label).to be_valid
      end
    end
  end

  describe 'callbacks' do
    it 'formats name before validation' do
      label = build(:label, name: 'My Label')
      label.valid?
      expect(label.name).to eq('my-label')
    end

    it 'formats color before save' do
      label = create(:label, color: '#abc')
      expect(label.reload.color).to eq('#ABC')
    end
  end
end
