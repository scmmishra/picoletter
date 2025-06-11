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
class Post < ApplicationRecord
  include Sluggable
  include Statusable
  include Timezonable

  sluggable_on :title, scope: :newsletter_id
  has_rich_text :content

  belongs_to :newsletter

  has_many :emails, dependent: :destroy_async
  has_many :email_clicks, dependent: :destroy_async
  enum :status, { draft: "draft", published: "published", archived: "archived", processing: "processing" }

  scope :published, -> { where(status: "published") }
  scope :drafts, -> { where(status: "draft") }
  scope :processing, -> { where(status: "processing") }
  scope :drafts_and_processing, -> { where(status: %w[draft processing]) }
  scope :archived, -> { where(status: "archived") }

  def self.slug_uniqueness_scope
    { scope: :newsletter_id }
  end

  def publish
    update(status: "published", published_at: Time.current)
  end

  def schedule(publish_at)
    update(scheduled_at: publish_at)
  end

  def unschedule
    update(scheduled_at: nil)
  end

  def archive
    update(status: "archived")
  end

  def scheduled?
    scheduled_at.present?
  end

  def publish_and_send(ignore_checks = false)
    return unless status == "draft"

    raise Exceptions::SubscriptionError unless newsletter.user.subscribed?
    raise Exceptions::UserNotActiveError unless can_send?

    PostValidationService.new(self).perform unless ignore_checks
    SendPostJob.perform_later(self.id)
    publish
  end

  def can_send?
    newsletter.user.active?
  end

  def self.claim_for_processing(post_id)
    post = find(post_id)
    post.with_lock do
      return nil unless post.draft?

      # Only claim if the post can actually be sent
      return nil unless post.newsletter.user.subscribed?
      return nil unless post.can_send?

      post.update!(status: "processing")
      post
    end
  rescue ActiveRecord::RecordNotFound
    nil
  rescue StandardError => e
    RorVsWild.record_error(e, context: { post: post_id })
    nil
  end

  def send_test_email(email)
    PostMailer.test_post(email, self).deliver_now
  end

  def published_on_date
    published_at.strftime("%B %d, %Y") if published_at.present?
  end

  def stats
    total = emails.count.to_f
    delivered = emails.delivered.count.to_f
    opened = emails.where.not(opened_at: nil).count.to_f
    bounced = emails.bounced.count.to_f
    total_clicks = email_clicks.count.to_f
    unique_clickers = email_clicks.joins(:email).distinct.count("emails.subscriber_id").to_f

    {
      total: total.to_i,
      delivered: delivered.to_i,
      opened: opened.to_i,
      bounced: bounced.to_i,
      total_clicks: total_clicks.to_i,
      unique_clickers: unique_clickers.to_i,
      delivery_rate: total.zero? ? 0 : (delivered / total * 100).round(1),
      bounce_rate: total.zero? ? 0 : (bounced / total * 100).round(1),
      open_rate: delivered.zero? ? 0 : (opened / delivered * 100).round(1),
      click_through_rate: delivered.zero? ? 0 : (unique_clickers / delivered * 100).round(1),
      click_to_open_rate: opened.zero? ? 0 : (unique_clickers / opened * 100).round(1)
    }
  end
end
