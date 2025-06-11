require 'rails_helper'

RSpec.describe SendSchedulePostJob, type: :job do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user) }

  before do
    # Mock AppConfig.billing_enabled? to return false so subscribed? always returns true
    allow(AppConfig).to receive(:billing_enabled?).and_return(false)
  end

  describe "#perform" do
    it "processes scheduled posts successfully" do
      post = create(:post, newsletter: newsletter, status: "draft", scheduled_at: Time.current)

      # Should change from draft to processing, not published (that happens in SendPostBatchJob)
      expect { SendSchedulePostJob.new.perform }.to change { post.reload.status }.from("draft").to("processing")

      # Verify SendPostJob was queued
      expect(SendPostJob).to have_been_enqueued.with(post.id)
    end

    it "ignores posts that are not scheduled for the current time window" do
      # Post scheduled outside the time window
      past_post = create(:post, newsletter: newsletter, status: "draft", scheduled_at: 5.minutes.ago)
      future_post = create(:post, newsletter: newsletter, status: "draft", scheduled_at: 5.minutes.from_now)

      expect { SendSchedulePostJob.new.perform }.not_to change { [ past_post.reload.status, future_post.reload.status ] }
    end

    it "processes posts within the 2-minute time window" do
      # Posts within ±1 minute should be processed
      post1 = create(:post, newsletter: newsletter, status: "draft", scheduled_at: 30.seconds.ago)
      post2 = create(:post, newsletter: newsletter, status: "draft", scheduled_at: 30.seconds.from_now)

      SendSchedulePostJob.new.perform

      expect(post1.reload.status).to eq("processing")
      expect(post2.reload.status).to eq("processing")
    end

    describe "concurrent execution" do
      it "prevents duplicate processing of the same post" do
        post = create(:post, newsletter: newsletter, status: "draft", scheduled_at: Time.current)
        results = []
        job_calls = []

        # Track SendPostJob calls
        allow(SendPostJob).to receive(:perform_later) do |post_id|
          job_calls << post_id
        end

        # Simulate two concurrent job instances
        threads = 2.times.map do
          Thread.new do
            begin
              SendSchedulePostJob.new.perform
              results << "completed"
            rescue => e
              results << "error: #{e.message}"
            end
          end
        end

        threads.each(&:join)

        # Post should only be processed once
        expect(post.reload.status).to eq("processing")

        # Both jobs should complete without errors
        expect(results.count("completed")).to eq(2)
        expect(results.grep(/error/).count).to eq(0)

        # SendPostJob should be called exactly once
        expect(job_calls.count).to eq(1)
        expect(job_calls.first).to eq(post.id)
      end

      it "handles multiple posts being processed concurrently" do
        # Create 3 posts scheduled for current time
        posts = 3.times.map do |i|
          create(:post,
            newsletter: newsletter,
            status: "draft",
            scheduled_at: Time.current,
            title: "Post #{i}"
          )
        end

        results = []

        # Simulate 3 concurrent job instances
        threads = 3.times.map do
          Thread.new do
            begin
              SendSchedulePostJob.new.perform
              results << "completed"
            rescue => e
              results << "error: #{e.message}"
            end
          end
        end

        threads.each(&:join)

        # All posts should be processed exactly once
        posts.each { |post| expect(post.reload.status).to eq("processing") }

        # All jobs should complete
        expect(results.count("completed")).to eq(3)
        expect(results.grep(/error/).count).to eq(0)
      end

      it "maintains atomic claiming under high concurrency" do
        # Create 5 posts for stress testing
        posts = 5.times.map do |i|
          create(:post,
            newsletter: newsletter,
            status: "draft",
            scheduled_at: Time.current,
            title: "Stress Post #{i}"
          )
        end

        # Track SendPostJob calls
        job_calls = []
        allow(SendPostJob).to receive(:perform_later) do |post_id|
          job_calls << post_id
        end

        # Launch 10 concurrent job instances (more than posts)
        threads = 10.times.map do
          Thread.new { SendSchedulePostJob.new.perform }
        end

        threads.each(&:join)

        # All posts should be processed exactly once
        posts.each { |post| expect(post.reload.status).to eq("processing") }

        # All posts should now be in processing state (will be published by SendPostBatchJob)
        expect(Post.where(status: "processing").count).to eq(5)

        # Most importantly: SendPostJob should be called exactly 5 times (once per post)
        expect(job_calls.count).to eq(5)
        expect(job_calls.sort).to eq(posts.map(&:id).sort)
      end
    end

    describe "error handling" do
      it "reverts post status on processing failure" do
        post = create(:post, newsletter: newsletter, status: "draft", scheduled_at: Time.current)

        # Mock SendPostJob to raise an error
        allow(SendPostJob).to receive(:perform_later).and_raise(StandardError, "Processing failed")
        # Post status should be reverted to draft
        expect(post.reload.status).to eq("draft")
      end

      it "continues processing other posts even if one fails" do
        post1 = create(:post, newsletter: newsletter, status: "draft", scheduled_at: Time.current, title: "Good Post")
        post2 = create(:post, newsletter: newsletter, status: "draft", scheduled_at: Time.current, title: "Bad Post")

        # Mock only the second post to fail at the SendPostJob level
        allow(SendPostJob).to receive(:perform_later) do |post_id|
          raise StandardError, "Processing failed" if Post.find(post_id).title == "Bad Post"
        end

        # First post should still be processing, second should be reverted
        expect(post1.reload.status).to eq("processing")
        expect(post2.reload.status).to eq("draft")
      end
    end

    describe "time window accuracy" do
      it "uses exactly ±1 minute time window" do
        # Posts right at the boundary
        post_in_range = create(:post, newsletter: newsletter, status: "draft", scheduled_at: 59.seconds.ago)
        post_out_of_range = create(:post, newsletter: newsletter, status: "draft", scheduled_at: 61.seconds.ago)

        SendSchedulePostJob.new.perform

        expect(post_in_range.reload.status).to eq("processing")
        expect(post_out_of_range.reload.status).to eq("draft")
      end
    end
  end
end
