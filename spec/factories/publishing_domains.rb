# == Schema Information
#
# Table name: publishing_domains
#
#  id                     :bigint           not null, primary key
#  cloudflare_ssl_status  :string
#  domain_type            :string           default("custom_cname"), not null
#  hostname               :string           not null
#  last_error             :text
#  status                 :string           default("pending"), not null
#  verification_http_body :text
#  verification_http_path :string
#  verification_method    :string
#  verified_at            :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  cloudflare_id          :string
#  newsletter_id          :bigint           not null
#
# Indexes
#
#  index_publishing_domains_on_hostname       (hostname) UNIQUE
#  index_publishing_domains_on_newsletter_id  (newsletter_id) UNIQUE
#
FactoryBot.define do
  factory :publishing_domain do
    newsletter
    sequence(:hostname) { |n| "custom-domain-#{n}.example.com" }
    domain_type { :custom_cname }
    status { :pending }
  end
end
