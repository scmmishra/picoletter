# == Schema Information
#
# Table name: posts
#
#  id            :integer          not null, primary key
#  content       :text
#  published_at  :datetime
#  scheduled_at  :datetime
#  status        :string           default("draft")
#  title         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  newsletter_id :integer          not null
#
# Indexes
#
#  index_posts_on_newsletter_id  (newsletter_id)
#
# Foreign Keys
#
#  newsletter_id  (newsletter_id => newsletters.id)
#
class Post < ApplicationRecord
  belongs_to :newsletter
  belongs_to :user, through: :newsletter
  enum status: { draft: "draft", scheduled: "scheduled", published: "published", archived: "archived" }

  scope :published, -> { where(status: "published") }
  scope :scheduled, -> { where(status: "scheduled") }
  scope :draft, -> { where(status: "draft") }
  scope :archived, -> { where(status: "archived") }

  def publish
    update(status: "published", published_at: Time.current)
  end

  def schedule(publish_at)
    update(status: "scheduled", scheduled_at: publish_at)
  end

  def archive
    update(status: "archived")
  end
end
