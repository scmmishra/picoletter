class SESVerificationService
  REGION = "us-east-1".freeze

  def initialize
    @client = Aws::SESV2::Client.new(region: REGION)
  end

  def create_identity(domain)
    # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SESV2/Client.html#create_email_identity-instance_method
    @client.create_email_identity({
      email_identity: domain
    })
  end

  def get_identity(domain)
    # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SESV2/Client.html#get_email_identity-instance_method
    @client.get_email_identity({
      email_identity: domain
    })
  end

  def create_tokens(domain)
    response = create_identity(domain)
    response.dkim_attributes.tokens
  rescue Aws::SESV2::Errors::AlreadyExistsException
    response = get_identity(domain)
    response.dkim_attributes.tokens
  end

  def verify_dns_tokens(tokens, domain)
    verified = tokens.map do |token|
      domain_to_check = "#{token}._domainkey.#{domain}"
      value_to_check = "#{token}.dkim.amazonses.com"

      DNSService.fetch_cname(domain_to_check) == value_to_check
    end

    verified.all?
  end

  def verified?(domain)
    response = get_identity(domain)
    response.verified_for_sending_status && response.dkim_attributes.status == "SUCCESS"
  end
end
