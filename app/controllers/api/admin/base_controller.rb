class Api::Admin::BaseController < Api::BaseController
  before_action :ensure_billing_enabled
  before_action :authenticate_api_key

  private

  def ensure_billing_enabled
    unless AppConfig.get("ENABLE_BILLING", false)
      return render json: { error: 'API access is not enabled' }, status: :forbidden
    end
  end

  def authenticate_api_key
    api_key = request.headers['X-Api-Key']
    expected_api_key = ENV['ADMIN_API_KEY']
    
    unless api_key.present? && ActiveSupport::SecurityUtils.secure_compare(api_key, expected_api_key)
      return render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
