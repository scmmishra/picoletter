# == Schema Information
#
# Table name: subscribers
#
#  id                 :integer          not null, primary key
#  created_via        :string
#  email              :string
#  full_name          :string
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
#
# Foreign Keys
#
#  newsletter_id  (newsletter_id => newsletters.id)
#
require 'rails_helper'

RSpec.describe Subscriber, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
