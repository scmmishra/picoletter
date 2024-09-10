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
  pending "add some examples to (or delete) #{__FILE__}"
end
