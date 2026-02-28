require 'rails_helper'

RSpec.describe Newsletters::Subscribers::LabelsController, type: :controller do
  let(:user) { create(:user) }
  let(:editor) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user) }
  let(:subscriber) { create(:subscriber, newsletter: newsletter, labels: []) }
  let(:label) { create(:label, newsletter: newsletter, name: "test-label") }
  let!(:editor_membership) { create(:membership, newsletter: newsletter, user: editor, role: :editor) }

  before do
    sign_in(user)
    allow(controller).to receive(:set_newsletter).and_return(newsletter)
    allow(controller).to receive(:set_subscriber).and_return(subscriber)
    controller.instance_variable_set(:@newsletter, newsletter)
    controller.instance_variable_set(:@subscriber, subscriber)
  end

  describe "POST #add" do
    it "adds a label to the subscriber" do
      label # ensure label is created

      expect {
        post :add, params: { slug: newsletter.slug, id: subscriber.id, label_name: label.name }, format: :turbo_stream
      }.to change { subscriber.reload.labels.count }.by(1)

      expect(subscriber.labels).to include(label.name)
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq "text/vnd.turbo-stream.html"
    end

    it "does not add a label that doesn't exist" do
      expect {
        post :add, params: { slug: newsletter.slug, id: subscriber.id, label_name: "non-existent" }, format: :turbo_stream
      }.not_to change { subscriber.reload.labels.count }

      expect(response).to have_http_status(:success)
    end

    it "does not add a label that's already added" do
      # First add the label
      subscriber.update(labels: [ label.name ])

      expect {
        post :add, params: { slug: newsletter.slug, id: subscriber.id, label_name: label.name }, format: :turbo_stream
      }.not_to change { subscriber.reload.labels.count }

      expect(subscriber.labels).to include(label.name)
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE #remove" do
    before do
      # Add the label first
      subscriber.update(labels: [ label.name ])
    end

    it "removes a label from the subscriber" do
      expect {
        delete :remove, params: { slug: newsletter.slug, id: subscriber.id, label_name: label.name }, format: :turbo_stream
      }.to change { subscriber.reload.labels.count }.by(-1)

      expect(subscriber.labels).not_to include(label.name)
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq "text/vnd.turbo-stream.html"
    end

    it "does not remove a label that doesn't exist" do
      expect {
        delete :remove, params: { slug: newsletter.slug, id: subscriber.id, label_name: "non-existent" }, format: :turbo_stream
      }.not_to change { subscriber.reload.labels.count }

      expect(response).to have_http_status(:success)
    end

    it "does not remove a label that's not added" do
      # Remove the label first
      subscriber.update(labels: [])

      expect {
        delete :remove, params: { slug: newsletter.slug, id: subscriber.id, label_name: label.name }, format: :turbo_stream
      }.not_to change { subscriber.reload.labels.count }

      expect(response).to have_http_status(:success)
    end
  end

  describe "authentication" do
    it "requires authentication" do
      sign_out

      post :add, params: { slug: newsletter.slug, id: subscriber.id, label_name: label.name }, format: :turbo_stream
      expect(response).to redirect_to("/auth/login")

      delete :remove, params: { slug: newsletter.slug, id: subscriber.id, label_name: label.name }, format: :turbo_stream
      expect(response).to redirect_to("/auth/login")
    end
  end

  describe "authorization" do
    before do
      sign_in(editor)
    end

    it "prevents editors from adding labels" do
      expect {
        post :add, params: { slug: newsletter.slug, id: subscriber.id, label_name: label.name }, format: :turbo_stream
      }.not_to change { subscriber.reload.labels.count }

      expect(response).to redirect_to(settings_profile_path(slug: newsletter.slug))
      expect(flash[:alert]).to eq("You don't have permission to access that section.")
    end

    it "prevents editors from removing labels" do
      subscriber.update!(labels: [ label.name ])

      expect {
        delete :remove, params: { slug: newsletter.slug, id: subscriber.id, label_name: label.name }, format: :turbo_stream
      }.not_to change { subscriber.reload.labels.count }

      expect(response).to redirect_to(settings_profile_path(slug: newsletter.slug))
      expect(flash[:alert]).to eq("You don't have permission to access that section.")
    end
  end
end
