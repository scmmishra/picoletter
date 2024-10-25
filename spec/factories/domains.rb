# == Schema Information
#
# Table name: domains
#
#  id            :bigint           not null, primary key
#  dkim_status   :string
#  dmarc_added   :boolean          default(FALSE)
#  error_message :string
#  is_verifying  :boolean          default(FALSE)
#  name          :string
#  public_key    :string
#  region        :string           default("us-east-1")
#  spf_details   :string
#  status        :integer
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
FactoryBot.define do
  factory :domain do
    name { "MyString" }
    team_id { 1 }
    status { 1 }
    region { "MyString" }
    click_tracking { false }
    open_tracking { false }
    public_key { "MyString" }
    dkim_status { "MyString" }
    spf_details { "MyString" }
    dmarc_added { false }
    error_message { "MyString" }
    subdomain { "MyString" }
    is_verifying { false }
  end
end
