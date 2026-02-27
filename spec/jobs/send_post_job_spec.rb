require "rails_helper"

RSpec.describe SendPostJob, type: :job do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user) }

  before do
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    ActiveJob::Base.queue_adapter.performed_jobs.clear
    Rails.cache.clear
    allow(AppConfig).to receive(:billing_enabled?).and_return(false)
  end

  describe "#perform" do
    it "skips posts that are not processing" do
      post = create(:post, newsletter: newsletter, status: "draft")

      described_class.new.perform(post.id)

      expect(post.reload.status).to eq("draft")
      expect(SendPostBatchJob).not_to have_been_enqueued
    end

    it "publishes immediately when there are no verified subscribers" do
      post = create(:post, newsletter: newsletter, status: "processing")

      expect {
        described_class.new.perform(post.id)
      }.to change { post.reload.status }.from("processing").to("published")

      expect(SendPostBatchJob).not_to have_been_enqueued
    end

    it "queues batch jobs for verified subscribers" do
      post = create(:post, newsletter: newsletter, status: "processing")
      subscriber_ids = create_list(:subscriber, 2, newsletter: newsletter, status: :verified).map(&:id)

      described_class.new.perform(post.id)

      expect(post.reload.status).to eq("processing")
      expect(SendPostBatchJob).to have_been_enqueued
      batch_job_payload = ActiveJob::Base.queue_adapter.enqueued_jobs.find { |job| job[:job] == SendPostBatchJob }
      expect(batch_job_payload[:args]).to eq([ post.id, subscriber_ids ])
    end
  end
end
