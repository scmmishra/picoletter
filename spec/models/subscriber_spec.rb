# == Schema Information
#
# Table name: subscribers
#
#  id                 :integer          not null, primary key
#  created_via        :string
#  email              :string
#  full_name          :string
#  notes              :text
#  referrer_url       :string
#  status             :integer          default("unverified")
#  unsubscribe_reason :string
#  unsubscribed_at    :datetime
#  utm_campaign       :string
#  utm_medium         :string
#  utm_source         :string
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
