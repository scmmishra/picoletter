# == Schema Information
#
# Table name: newsletters
#
#  id                        :integer          not null, primary key
#  description               :text
#  dns_records               :json
#  domain                    :string
#  domain_verification_token :string
#  domain_verified           :boolean          default(FALSE)
#  email_css                 :text
#  email_footer              :string
#  font_preference           :string           default("sans-serif")
#  primary_color             :string           default("#09090b")
#  reply_to                  :string
#  sending_address           :string
#  slug                      :string           not null
#  status                    :string
#  template                  :string
#  timezone                  :string           default("UTC"), not null
#  title                     :string
#  use_custom_domain         :boolean
#  website                   :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  domain_id                 :string
#  user_id                   :integer          not null
#
# Indexes
#
#  index_newsletters_on_slug     (slug)
#  index_newsletters_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
require "test_helper"

class NewsletterTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
