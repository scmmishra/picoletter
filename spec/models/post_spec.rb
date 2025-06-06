# == Schema Information
#
# Table name: posts
#
#  id            :bigint           not null, primary key
#  content       :text
#  published_at  :datetime
#  scheduled_at  :datetime
#  slug          :string           not null
#  status        :string           default("draft")
#  title         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  newsletter_id :integer          not null
#
# Indexes
#
#  index_posts_on_newsletter_id           (newsletter_id)
#  index_posts_on_newsletter_id_and_slug  (newsletter_id,slug) UNIQUE
#  index_posts_on_slug                    (slug)
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
require 'rails_helper'

RSpec.describe Post, type: :model do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user) }
  let(:post) { create(:post, newsletter: newsletter, status: "draft") }

  describe ".claim_for_processing" do
    it "claims a draft post and sets status to processing" do
      claimed_post = Post.claim_for_processing(post.id)

      expect(claimed_post).to eq(post)
      expect(claimed_post.status).to eq("processing")
    end

    it "returns nil when post is not draft" do
      post.update!(status: "published")

      claimed_post = Post.claim_for_processing(post.id)

      expect(claimed_post).to be_nil
    end

    it "returns nil when post doesn't exist" do
      claimed_post = Post.claim_for_processing(999999)

      expect(claimed_post).to be_nil
    end

    it "prevents concurrent claiming of the same post" do
      results = []
      exceptions = []

      # Simulate two concurrent attempts to claim the same post
      threads = 2.times.map do
        Thread.new do
          begin
            result = Post.claim_for_processing(post.id)
            results << result
          rescue => e
            exceptions << e
          end
        end
      end

      threads.each(&:join)

      # Only one thread should successfully claim the post
      successful_claims = results.compact
      expect(successful_claims.count).to eq(1)
      expect(successful_claims.first.status).to eq("processing")

      # The other attempt should return nil
      expect(results).to include(nil)

      # No exceptions should occur
      expect(exceptions).to be_empty
    end

    it "handles concurrent attempts on different posts correctly" do
      post2 = create(:post, newsletter: newsletter, status: "draft")
      results = []

      # Simulate concurrent claiming of different posts
      threads = [
        Thread.new { results << Post.claim_for_processing(post.id) },
        Thread.new { results << Post.claim_for_processing(post2.id) }
      ]

      threads.each(&:join)

      # Both posts should be successfully claimed
      expect(results.compact.count).to eq(2)
      expect(results.map(&:id).sort).to eq([ post.id, post2.id ].sort)
      expect(results.all? { |p| p.status == "processing" }).to be true
    end

    it "maintains data integrity under concurrent load" do
      # Create multiple draft posts
      posts = 5.times.map { create(:post, newsletter: newsletter, status: "draft") }
      results = []

      # Try to claim all posts concurrently
      threads = posts.map do |p|
        Thread.new { results << Post.claim_for_processing(p.id) }
      end

      threads.each(&:join)

      # All posts should be successfully claimed
      expect(results.compact.count).to eq(5)
      expect(results.compact.all? { |p| p.status == "processing" }).to be true

      # Verify database state is consistent
      processing_posts = Post.where(status: "processing")
      expect(processing_posts.count).to eq(5)
    end
  end
end
