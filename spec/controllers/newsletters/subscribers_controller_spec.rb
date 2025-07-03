require "rails_helper"

RSpec.describe Newsletters::SubscribersController, type: :controller do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user) }
  let(:other_user) { create(:user) }
  let(:other_newsletter) { create(:newsletter, user: other_user) }

  before do
    sign_in(user)
    allow(controller).to receive(:default_url_options).and_return(host: "test.host")
  end

  describe "authentication and authorization" do
    it "requires authentication" do
      sign_out
      get :index, params: { slug: newsletter.slug }
      expect(response).to redirect_to(auth_login_path)
    end

    it "redirects to first newsletter if newsletter not found" do
      first_newsletter = create(:newsletter, user: user)
      get :index, params: { slug: "non-existent-slug" }
      expect(response).to redirect_to(newsletter_url(first_newsletter.slug))
    end

    it "prevents access to other users' newsletters" do
      # Create a newsletter for current user to redirect to
      user_newsletter = create(:newsletter, user: user)
      get :index, params: { slug: other_newsletter.slug }
      expect(response).to redirect_to(newsletter_url(user_newsletter.slug))
    end
  end

  describe "GET #index" do
    let!(:verified_subscriber1) { create(:subscriber, newsletter: newsletter, status: :verified, created_at: 2.days.ago) }
    let!(:verified_subscriber2) { create(:subscriber, newsletter: newsletter, status: :verified, created_at: 1.day.ago) }
    let!(:unverified_subscriber) { create(:subscriber, newsletter: newsletter, status: :unverified) }
    let!(:unsubscribed_subscriber) { create(:subscriber, :unsubscribed, newsletter: newsletter) }

    it "renders successfully" do
      get :index, params: { slug: newsletter.slug }
      expect(response).to have_http_status(:success)
    end

    it "assigns newsletter" do
      get :index, params: { slug: newsletter.slug }
      expect(controller.instance_variable_get(:@newsletter)).to eq(newsletter)
    end

    context "filtering by status" do
      it "filters by verified status when status param is 'verified'" do
        get :index, params: { slug: newsletter.slug, status: "verified" }
        expect(response).to have_http_status(:success)
      end

      it "filters by unverified status when status param is 'unverified'" do
        get :index, params: { slug: newsletter.slug, status: "unverified" }
        expect(response).to have_http_status(:success)
      end

      it "filters by unsubscribed status when status param is 'unsubscribed'" do
        get :index, params: { slug: newsletter.slug, status: "unsubscribed" }
        expect(response).to have_http_status(:success)
      end

      it "defaults to verified status when no status param provided" do
        get :index, params: { slug: newsletter.slug }
        expect(response).to have_http_status(:success)
      end
    end

    context "pagination" do
      before do
        # Create more than 30 subscribers to test pagination
        create_list(:subscriber, 35, newsletter: newsletter, status: :verified)
      end

      it "handles pagination" do
        get :index, params: { slug: newsletter.slug }
        expect(response).to have_http_status(:success)
        expect(controller.instance_variable_get(:@pagy)).to be_present
      end

      it "handles page parameter" do
        get :index, params: { slug: newsletter.slug, page: 2 }
        expect(response).to have_http_status(:success)
      end

      it "limits to 30 subscribers per page" do
        get :index, params: { slug: newsletter.slug }
        pagy = controller.instance_variable_get(:@pagy)
        expect(pagy.limit).to eq(30)
      end
    end
  end

  describe "GET #show" do
    let(:subscriber) { create(:subscriber, newsletter: newsletter) }

    it "renders successfully" do
      get :show, params: { slug: newsletter.slug, id: subscriber.id }
      expect(response).to have_http_status(:success)
    end

    it "assigns the correct subscriber" do
      get :show, params: { slug: newsletter.slug, id: subscriber.id }
      expect(controller.instance_variable_get(:@subscriber)).to eq(subscriber)
    end

    it "raises error for non-existent subscriber" do
      expect {
        get :show, params: { slug: newsletter.slug, id: 99999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "PATCH #update" do
    let(:subscriber) { create(:subscriber, newsletter: newsletter) }
    let(:valid_params) do
      {
        slug: newsletter.slug,
        id: subscriber.id,
        subscriber: {
          email: "updated@example.com",
          full_name: "Updated Name",
          notes: "Updated notes"
        }
      }
    end

    context "with valid parameters" do
      it "updates the subscriber" do
        patch :update, params: valid_params

        subscriber.reload
        expect(subscriber.email).to eq("updated@example.com")
        expect(subscriber.full_name).to eq("Updated Name")
        expect(subscriber.notes).to eq("Updated notes")
      end

      it "redirects to subscriber show page with success notice" do
        patch :update, params: valid_params

        expect(response).to redirect_to(subscriber_url(newsletter.slug, subscriber.id))
        expect(flash[:notice]).to eq("Subscriber updated successfully")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          slug: newsletter.slug,
          id: subscriber.id,
          subscriber: {
            email: "" # Assuming email is required
          }
        }
      end

      it "raises error on validation failure" do
        expect {
          patch :update, params: invalid_params
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it "only permits allowed parameters" do
      original_status = subscriber.status

      patch :update, params: {
        slug: newsletter.slug,
        id: subscriber.id,
        subscriber: {
          email: "test@example.com",
          full_name: "Test Name",
          notes: "Test notes",
          status: "unsubscribed", # Should not be permitted
          newsletter_id: 999 # Should not be permitted
        }
      }

      subscriber.reload
      expect(subscriber.email).to eq("test@example.com")
      expect(subscriber.full_name).to eq("Test Name")
      expect(subscriber.notes).to eq("Test notes")
      expect(subscriber.status).to eq(original_status) # Should not have changed
      expect(subscriber.newsletter_id).to eq(newsletter.id) # Should not have changed
    end
  end

  describe "DELETE #destroy" do
    let!(:subscriber) { create(:subscriber, newsletter: newsletter) }

    it "destroys the subscriber" do
      expect {
        delete :destroy, params: { slug: newsletter.slug, id: subscriber.id }
      }.to change(Subscriber, :count).by(-1)
    end

    it "redirects to subscribers index with success notice" do
      delete :destroy, params: { slug: newsletter.slug, id: subscriber.id }

      expect(response).to redirect_to(subscribers_url(newsletter.slug))
      expect(flash[:notice]).to eq("Subscriber deleted successfully")
    end

    it "raises error for non-existent subscriber" do
      expect {
        delete :destroy, params: { slug: newsletter.slug, id: 99999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "PATCH #unsubscribe" do
    let(:subscriber) { create(:subscriber, newsletter: newsletter, status: :verified) }

    it "calls unsubscribe! on the subscriber" do
      expect_any_instance_of(Subscriber).to receive(:unsubscribe!)

      patch :unsubscribe, params: { slug: newsletter.slug, id: subscriber.id }
    end

    it "redirects to subscriber show page with success notice" do
      allow_any_instance_of(Subscriber).to receive(:unsubscribe!)

      patch :unsubscribe, params: { slug: newsletter.slug, id: subscriber.id }

      expect(response).to redirect_to(subscriber_url(newsletter.slug, subscriber.id))
      expect(flash[:notice]).to include("has been unsubscribed.")
    end

    it "includes subscriber display name in notice" do
      allow_any_instance_of(Subscriber).to receive(:unsubscribe!)
      subscriber.update!(full_name: "John Doe")

      patch :unsubscribe, params: { slug: newsletter.slug, id: subscriber.id }

      expect(flash[:notice]).to include("John Doe")
    end
  end

  describe "PATCH #send_reminder" do
    let(:subscriber) { create(:subscriber, newsletter: newsletter, status: :unverified) }

    it "calls send_reminder on the subscriber" do
      expect_any_instance_of(Subscriber).to receive(:send_reminder)

      patch :send_reminder, params: { slug: newsletter.slug, id: subscriber.id }
    end

    it "redirects to subscriber show page with success notice" do
      allow_any_instance_of(Subscriber).to receive(:send_reminder)

      patch :send_reminder, params: { slug: newsletter.slug, id: subscriber.id }

      expect(response).to redirect_to(subscriber_url(newsletter.slug, subscriber.id))
      expect(flash[:notice]).to eq("Reminder sent.")
    end
  end

  describe "error handling" do
    let(:subscriber) { create(:subscriber, newsletter: newsletter) }

    it "handles database errors gracefully on destroy" do
      allow_any_instance_of(Subscriber).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)

      expect {
        delete :destroy, params: { slug: newsletter.slug, id: subscriber.id }
      }.to raise_error(ActiveRecord::RecordNotDestroyed)
    end

    it "handles database errors gracefully on update" do
      allow_any_instance_of(Subscriber).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)

      expect {
        patch :update, params: {
          slug: newsletter.slug,
          id: subscriber.id,
          subscriber: { email: "test@example.com" }
        }
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "handles subscriber not found errors" do
      expect {
        get :show, params: { slug: newsletter.slug, id: 99999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "newsletter access control" do
    let(:subscriber) { create(:subscriber, newsletter: newsletter) }
    let(:other_subscriber) { create(:subscriber, newsletter: other_newsletter) }

    it "prevents access to subscribers from different newsletters" do
      expect {
        get :show, params: { slug: newsletter.slug, id: other_subscriber.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "prevents updating subscribers from different newsletters" do
      expect {
        patch :update, params: {
          slug: newsletter.slug,
          id: other_subscriber.id,
          subscriber: { email: "hacker@example.com" }
        }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "prevents deleting subscribers from different newsletters" do
      expect {
        delete :destroy, params: { slug: newsletter.slug, id: other_subscriber.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "Pagy integration" do
    it "uses Pagy for pagination" do
      create_list(:subscriber, 5, newsletter: newsletter, status: :verified)

      get :index, params: { slug: newsletter.slug }

      pagy = controller.instance_variable_get(:@pagy)
      subscribers = controller.instance_variable_get(:@subscribers)

      expect(pagy).to be_a(Pagy)
      expect(subscribers).to respond_to(:each) # Should be enumerable
    end

    it "respects the limit parameter" do
      get :index, params: { slug: newsletter.slug }

      pagy = controller.instance_variable_get(:@pagy)
      expect(pagy.limit).to eq(30)
    end

    it "handles status filtering with pagination" do
      create_list(:subscriber, 10, newsletter: newsletter, status: :verified)
      create_list(:subscriber, 10, newsletter: newsletter, status: :unverified)

      get :index, params: { slug: newsletter.slug, status: "unverified" }

      expect(response).to have_http_status(:success)
      pagy = controller.instance_variable_get(:@pagy)
      expect(pagy).to be_present
    end
  end
end
