# == Schema Information
#
# Table name: domains
#
#  id            :bigint           not null, primary key
#  dkim_status   :string           default("pending")
#  dmarc_added   :boolean          default(FALSE)
#  error_message :string
#  name          :string
#  public_key    :string
#  region        :string           default("us-east-1")
#  spf_status    :string           default("pending")
#  status        :string           default("pending")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  newsletter_id :bigint           not null
#
# Indexes
#
#  index_domains_on_name           (name) UNIQUE
#  index_domains_on_newsletter_id  (newsletter_id)
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
require 'rails_helper'

RSpec.describe Domain, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
