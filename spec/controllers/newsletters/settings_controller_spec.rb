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

      it 'allows access to design settings (read-only)' do
        get :design, params: { slug: newsletter.slug }
        expect(response).to have_http_status(:success)
      end

      it 'redirects from sending settings' do
        get :sending, params: { slug: newsletter.slug }
        expect(response).to redirect_to(profile_settings_path(slug: newsletter.slug))
        expect(flash[:alert]).to include("You don't have permission")
      end

      it 'allows access to profile settings' do
        get :profile, params: { slug: newsletter.slug }
        expect(response).to have_http_status(:success)
      end

      it 'allows access to embedding settings' do
        get :embedding, params: { slug: newsletter.slug }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is the owner' do
      before do
        sign_in(owner)
      end

      it 'allows access to all settings' do
        get :show, params: { slug: newsletter.slug }
        expect(response).to have_http_status(:success)

        get :design, params: { slug: newsletter.slug }
        expect(response).to have_http_status(:success)

        get :sending, params: { slug: newsletter.slug }
        expect(response).to have_http_status(:success)

        get :profile, params: { slug: newsletter.slug }
        expect(response).to have_http_status(:success)

        get :embedding, params: { slug: newsletter.slug }
        expect(response).to have_http_status(:success)
      end
    end
  end
end
