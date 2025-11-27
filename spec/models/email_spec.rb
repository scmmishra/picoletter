# == Schema Information
#
# Table name: emails
#
#  id             :string           not null, primary key
#  bounced_at     :datetime
#  complained_at  :datetime
#  delivered_at   :datetime
#  emailable_type :string
#  opened_at      :datetime
#  status         :string           default("sent")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  emailable_id   :bigint
#  post_id        :bigint
#  subscriber_id  :integer
#
# Indexes
#
#  index_emails_on_emailable_type_and_emailable_id  (emailable_type,emailable_id)
#  index_emails_on_post_id                          (post_id)
#  index_emails_on_subscriber_id                    (subscriber_id)
#
# Foreign Keys
#
#  fk_rails_...  (subscriber_id => subscribers.id)
#
require 'rails_helper'

RSpec.describe Email, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
