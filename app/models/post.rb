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
    user.active?
  end

  def send_test_email(email)
    PostMailer.test_post(email, self).deliver_now
  end

  def published_on_date
    published_at.strftime("%B %d, %Y") if published_at.present?
  end
end
