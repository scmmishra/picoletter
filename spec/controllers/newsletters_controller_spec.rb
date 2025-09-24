require 'rails_helper'

RSpec.describe NewslettersController, type: :controller do
  let(:user) { create(:user, :verified) }

  before do
    sign_in(user)
    @request.host = 'localhost'
  end

  describe 'GET #new' do
    it 'builds a new owned newsletter for the current user' do
      get :new

      newsletter = controller.instance_variable_get(:@newsletter)

      expect(newsletter).to be_a(Newsletter)
      expect(newsletter).to be_new_record
      expect(newsletter.user).to eq(user)
    end
  end

  describe 'POST #create' do
    let(:newsletter_params) do
      {
        newsletter: {
          title: 'My Newsletter',
          description: 'All the latest updates',
          slug: "my-newsletter-#{SecureRandom.hex(4)}",
          timezone: 'UTC'
        }
      }
    end

    it 'creates a newsletter owned by the current user' do
      expect do
        post :create, params: newsletter_params
      end.to change(Newsletter, :count).by(1)
        .and change(Membership, :count).by(1)

      newsletter = Newsletter.last

      expect(newsletter.user).to eq(user)
      expect(newsletter.memberships.find_by(user: user)).to be_administrator
      expect(response).to redirect_to(posts_url(newsletter.slug))
    end

    it 'renders the form again when validation fails' do
      invalid_params = newsletter_params.deep_dup
      invalid_params[:newsletter][:title] = ''

      expect do
        post :create, params: invalid_params
      end.not_to change(Newsletter, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(controller.instance_variable_get(:@newsletter).user).to eq(user)
    end
  end
end
