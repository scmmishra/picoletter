class Core::BaseService
  REGION = "us-east-1".freeze

  def initialize
    @client = Aws::SESV2::Client.new(region: REGION)
  end
end
