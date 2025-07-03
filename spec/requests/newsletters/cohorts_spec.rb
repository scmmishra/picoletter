require 'rails_helper'

RSpec.describe Newsletters::CohortsController, type: :controller do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user) }
  let(:cohort) { create(:cohort, newsletter: newsletter) }

  before do
    sign_in(user)
    allow(controller).to receive(:default_url_options).and_return(host: "test.host")
  end

  describe "GET #index" do
    it "returns http success" do
      get :index, params: { slug: newsletter.slug }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    it "returns http success" do
      get :show, params: { slug: newsletter.slug, id: cohort.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #new" do
    it "returns http success" do
      get :new, params: { slug: newsletter.slug }
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      let(:valid_params) do
        {
          slug: newsletter.slug,
          cohort: {
            name: "Test Cohort",
            description: "A test cohort",
            emoji: "🧪",
            label_ids: []
          }
        }
      end

      it "creates a new cohort" do
        expect {
          post :create, params: valid_params
        }.to change(newsletter.cohorts, :count).by(1)
      end

      it "redirects to the cohort" do
        post :create, params: valid_params
        expect(response).to have_http_status(:redirect)
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          slug: newsletter.slug,
          cohort: { name: "" }
        }
      end

      it "does not create a cohort" do
        expect {
          post :create, params: invalid_params
        }.not_to change(Cohort, :count)
      end

      it "renders the new template" do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET #edit" do
    it "returns http success" do
      get :edit, params: { slug: newsletter.slug, id: cohort.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH #update" do
    context "with valid params" do
      it "updates the cohort" do
        patch :update, params: {
          slug: newsletter.slug,
          id: cohort.id,
          cohort: { name: "Updated Cohort" }
        }

        expect(response).to have_http_status(:redirect)
        expect(cohort.reload.name).to eq("Updated Cohort")
      end
    end

    context "with invalid params" do
      it "renders the edit template" do
        patch :update, params: {
          slug: newsletter.slug,
          id: cohort.id,
          cohort: { name: "" }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the cohort" do
      cohort # Create the cohort

      expect {
        delete :destroy, params: { slug: newsletter.slug, id: cohort.id }
      }.to change(newsletter.cohorts, :count).by(-1)
    end

    it "redirects to cohorts index" do
      delete :destroy, params: { slug: newsletter.slug, id: cohort.id }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "authorization" do
    let(:other_user) { create(:user) }
    let(:other_newsletter) { create(:newsletter, user: other_user) }
    let(:other_cohort) { create(:cohort, newsletter: other_newsletter) }

    it "does not allow access to other user's cohorts" do
      expect {
        get :show, params: { slug: other_newsletter.slug, id: other_cohort.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
