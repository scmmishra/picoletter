class BaseAwsService
  REGION = "us-east-1".freeze

  def initialize
    region = ENV["AWS_REGION"] || REGION
    credentials = Aws::Credentials.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_ACCESS_KEY"])
    @client = Aws::SESV2::Client.new(region:, credentials:)
  end
end
