# == Schema Information
#
# Table name: memberships
#
#  id            :bigint           not null, primary key
#  role          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  newsletter_id :bigint           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_memberships_on_newsletter_id              (newsletter_id)
#  index_memberships_on_role                       (role)
#  index_memberships_on_user_id                    (user_id)
#  index_memberships_on_user_id_and_newsletter_id  (user_id,newsletter_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Membership, type: :model do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:newsletter) }
  end

  describe 'validations' do
    it { should validate_presence_of(:role) }

    it 'validates uniqueness of user per newsletter' do
      create(:membership, user: user, newsletter: newsletter)
      duplicate_membership = build(:membership, user: user, newsletter: newsletter)

      expect(duplicate_membership).not_to be_valid
      expect(duplicate_membership.errors[:user_id]).to include('has already been taken')
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(administrator: 'administrator', editor: 'editor').backed_by_column_of_type(:string) }
  end

  describe 'scopes' do
    let(:another_newsletter) { create(:newsletter) }
    let!(:admin_membership) { create(:membership, :administrator, user: user, newsletter: another_newsletter) }
    let!(:editor_membership) { create(:membership, :editor, user: create(:user), newsletter: another_newsletter) }

    describe '.administrators' do
      it 'returns only administrator memberships' do
        expect(Membership.administrators).to include(admin_membership)
        expect(Membership.administrators).not_to include(editor_membership)
      end
    end

    describe '.editors' do
      it 'returns only editor memberships' do
        expect(Membership.editors).to include(editor_membership)
        expect(Membership.editors).not_to include(admin_membership)
      end
    end
  end

  describe 'role methods' do
    let(:admin_membership) { create(:membership, :administrator) }
    let(:editor_membership) { create(:membership, :editor) }

    it 'correctly identifies administrator role' do
      expect(admin_membership.administrator?).to be true
      expect(admin_membership.editor?).to be false
    end

    it 'correctly identifies editor role' do
      expect(editor_membership.administrator?).to be false
      expect(editor_membership.editor?).to be true
    end
  end
end
