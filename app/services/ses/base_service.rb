class SES::BaseService
  REGION = "us-east-1".freeze

  def initalize
    @client = Aws::SESV2::Client.new(region: REGION)
    @region = REGION
  end
end
