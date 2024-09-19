# == Schema Information
#
# Table name: subscribers
#
#  id                 :bigint           not null, primary key
#  analytics_data     :jsonb
#  created_via        :string
#  email              :string
#  full_name          :string
#  notes              :text
#  status             :integer          default("unverified")
#  unsubscribe_reason :string
#  unsubscribed_at    :datetime
#  verified_at        :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  newsletter_id      :integer          not null
#
# Indexes
#
#  index_subscribers_on_newsletter_id  (newsletter_id)
#  index_subscribers_on_status         (status)
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
require 'rails_helper'

RSpec.describe Subscriber, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
