class SesVerificationService
  REGION = "us-east-1".freeze

  def initialize
    @client = Aws::SESV2::Client.new(region: REGION)
  end

  def create_identity(domain)
    @client.create_email_identity({
      email_identity: domain
    })
  end

  def get_identity(domain)
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

  def verified?(domain)
    response = get_identity(domain)
    response.verified_for_sending_status && response.dkim_attributes.status == "SUCCESS"
  end
end