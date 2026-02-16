class Api::V1::BaseController < Api::BaseController
  before_action :authenticate_token!

  private

  def authenticate_token!
    raw_token = extract_bearer_token
    @api_token = ApiToken.find_by(token: raw_token)

    unless @api_token && ActiveSupport::SecurityUtils.secure_compare(@api_token.token, raw_token.to_s)
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    @newsletter = @api_token.newsletter
  end

  def extract_bearer_token
    header = request.headers["Authorization"]
    header&.match(/\ABearer (\S+)\z/)&.captures&.first
  end
end
