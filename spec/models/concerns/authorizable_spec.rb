require 'rails_helper'

RSpec.describe Authorizable, type: :concern do
  let(:newsletter) { create(:newsletter) }
  let(:owner) { newsletter.user }
  let(:admin_user) { create(:user) }
  let(:editor_user) { create(:user) }
  let(:non_member) { create(:user) }

  before do
    # Create memberships
    create(:membership, user: admin_user, newsletter: newsletter, role: :administrator)
    create(:membership, user: editor_user, newsletter: newsletter, role: :editor)
  end

  describe '#can_access?' do
    context 'for owner' do
      before { allow(Current).to receive(:user).and_return(owner) }

      it 'can access all sections' do
        expect(newsletter.can_access?(:general)).to be true
        expect(newsletter.can_access?(:design)).to be true
        expect(newsletter.can_access?(:sending)).to be true
        expect(newsletter.can_access?(:billing)).to be true
        expect(newsletter.can_access?(:profile)).to be true
        expect(newsletter.can_access?(:embedding)).to be true
      end
    end

    context 'for administrator' do
      before { allow(Current).to receive(:user).and_return(admin_user) }

      it 'can access all sections' do
        expect(newsletter.can_access?(:general)).to be true
        expect(newsletter.can_access?(:design)).to be true
        expect(newsletter.can_access?(:sending)).to be true
        expect(newsletter.can_access?(:billing)).to be true
        expect(newsletter.can_access?(:profile)).to be true
        expect(newsletter.can_access?(:embedding)).to be true
      end
    end

    context 'for editor' do
      before { allow(Current).to receive(:user).and_return(editor_user) }

      it 'can access general, design, profile and embedding for reading' do
        expect(newsletter.can_access?(:general)).to be true
        expect(newsletter.can_access?(:design)).to be true
        expect(newsletter.can_access?(:sending)).to be false
        expect(newsletter.can_access?(:billing)).to be false
        expect(newsletter.can_access?(:profile)).to be true
        expect(newsletter.can_access?(:embedding)).to be true
      end
    end

    context 'for non-member' do
      before { allow(Current).to receive(:user).and_return(non_member) }

      it 'cannot access any sections' do
        expect(newsletter.can_access?(:general)).to be false
        expect(newsletter.can_access?(:design)).to be false
        expect(newsletter.can_access?(:sending)).to be false
        expect(newsletter.can_access?(:billing)).to be false
        expect(newsletter.can_access?(:profile)).to be false
        expect(newsletter.can_access?(:embedding)).to be false
      end
    end

    context 'for invalid permission' do
      before { allow(Current).to receive(:user).and_return(owner) }

      it 'returns false for non-existent permission' do
        expect(newsletter.can_access?(:invalid_permission)).to be false
      end
    end
  end

  describe '#can_read?' do
    context 'team section' do
      it 'allows owner, administrator, and editor to read team settings' do
        allow(Current).to receive(:user).and_return(owner)
        expect(newsletter.can_read?(:team)).to be true

        allow(Current).to receive(:user).and_return(admin_user)
        expect(newsletter.can_read?(:team)).to be true

        allow(Current).to receive(:user).and_return(editor_user)
        expect(newsletter.can_read?(:team)).to be true
      end

      it 'denies non members' do
        allow(Current).to receive(:user).and_return(non_member)
        expect(newsletter.can_read?(:team)).to be false
      end
    end
  end

  describe '#can_write?' do
    context 'team section' do
      it 'allows owner and administrator to manage team settings' do
        allow(Current).to receive(:user).and_return(owner)
        expect(newsletter.can_write?(:team)).to be true

        allow(Current).to receive(:user).and_return(admin_user)
        expect(newsletter.can_write?(:team)).to be true
      end

      it 'denies editors and non members' do
        allow(Current).to receive(:user).and_return(editor_user)
        expect(newsletter.can_write?(:team)).to be false

        allow(Current).to receive(:user).and_return(non_member)
        expect(newsletter.can_write?(:team)).to be false
      end
    end
  end
end
