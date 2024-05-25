FactoryBot.define do
  factory(:newsletter) do
    description {"Nice description"}
    domain { "picoletter.com" }
    domain_id { "uuid-domain-id" }
    domain_verified { true }
    reply_to { "shivam@picoletter.com" }
    sending_address { "shivam@picoletter.com" }
    slug { "tinyjs" }
    status { nil }
    template { nil }
    timezone { "UTC" }
    title { "TinyJS" }
    use_custom_domain { true }
    user_id { 16 }
    website { nil }
  end
end
