require 'rails_helper'

RSpec.describe Newsletters::SettingsController, type: :controller do
  let(:newsletter) { create(:newsletter) }
  let(:owner) { newsletter.user }
  let(:editor_user) { create(:user) }

  before do
    create(:membership, user: editor_user, newsletter: newsletter, role: :editor)
  end

  describe 'authorization' do
    context 'when user is an editor' do
      before do
        sign_in(editor_user)
      end

      it 'allows access to general settings (read-only)' do
        get :show, params: { slug: newsletter.slug }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is the owner' do
      before do
        sign_in(owner)
      end

      it 'allows access to general settings' do
        get :show, params: { slug: newsletter.slug }
        expect(response).to have_http_status(:success)
      end
    end
  end
end
