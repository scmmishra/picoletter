class BaseAwsService
  REGION = "us-east-1".freeze

  def initialize
    region = AppConfig.get("AWS_REGION", REGION)
    key = AppConfig.get!("AWS_ACCESS_KEY_ID")
    secret = AppConfig.get!("AWS_SECRET_ACCESS_KEY")

    credentials = Aws::Credentials.new(key, secret)
    @ses_client = Aws::SESV2::Client.new(region:, credentials:)
  end

  private
end
