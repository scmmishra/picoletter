require "rails_helper"

RSpec.describe Newsletters::PostsController, type: :controller do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user) }
  let(:post_record) { create(:post, newsletter: newsletter, status: "draft") }

  before do
    sign_in(user)
    @request.host = "localhost"
    allow(controller).to receive(:default_url_options).and_return(host: "localhost")
  end

  describe "POST #schedule" do
    it "schedules the post from epoch milliseconds as a UTC timestamp" do
      scheduled_utc = Time.utc(2026, 2, 27, 16, 0, 0)

      post :schedule, params: {
        slug: newsletter.slug,
        id: post_record.id,
        post: { scheduled_at_epoch_ms: (scheduled_utc.to_f * 1000).to_i.to_s }
      }

      expect(response).to redirect_to(edit_post_url(slug: newsletter.slug, id: post_record.id))
      expect(flash[:notice]).to eq("Post was successfully scheduled.")
      expect(post_record.reload.scheduled_at.to_i).to eq(scheduled_utc.to_i)
      expect(post_record.reload.scheduled_at.utc).to eq(scheduled_utc)
    end

    it "does not schedule when epoch milliseconds are blank" do
      allow(Rails.error).to receive(:report)

      post :schedule, params: {
        slug: newsletter.slug,
        id: post_record.id,
        post: { scheduled_at_epoch_ms: "" }
      }

      expect(response).to redirect_to(edit_post_url(slug: newsletter.slug, id: post_record.id))
      expect(flash[:notice]).to eq("Something went wrong while publishing the post")
      expect(post_record.reload.scheduled_at).to be_nil
      expect(Rails.error).to have_received(:report).with(instance_of(ArgumentError), anything)
    end

    it "does not schedule when epoch milliseconds are not numeric" do
      allow(Rails.error).to receive(:report)

      post :schedule, params: {
        slug: newsletter.slug,
        id: post_record.id,
        post: { scheduled_at_epoch_ms: "not-a-number" }
      }

      expect(response).to redirect_to(edit_post_url(slug: newsletter.slug, id: post_record.id))
      expect(flash[:notice]).to eq("Something went wrong while publishing the post")
      expect(post_record.reload.scheduled_at).to be_nil
      expect(Rails.error).to have_received(:report).with(instance_of(ArgumentError), anything)
    end
  end
end
