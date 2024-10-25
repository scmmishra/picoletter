class SES::BaseService
  REGION = "us-east-1".freeze

  def initialize
    credentials = Aws::Credentials.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_ACCESS_KEY"])
    @client = Aws::SESV2::Client.new(region: REGION, credentials: credentials)
  end
end
