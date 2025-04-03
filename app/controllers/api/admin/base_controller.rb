class Api::Admin::BaseController < Api::BaseController
  before_action :ensure_billing_enabled
  before_action :authenticate_api_key
  before_action :verify_hmac, except: [:index, :show]

  private

  def ensure_billing_enabled
    unless AppConfig.get("ENABLE_BILLING", false)
      return render json: { error: 'API access is not enabled' }, status: :forbidden
    end
  end

  def authenticate_api_key
    api_key = request.headers['X-API-Key']
    expected_api_key = ENV['ADMIN_API_KEY']
    
    unless api_key.present? && ActiveSupport::SecurityUtils.secure_compare(api_key, expected_api_key)
      return render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def verify_hmac
    # Skip HMAC verification if no payload
    return true if request.raw_post.blank?

    signature = request.headers['X-HMAC-Signature']
    timestamp = request.headers['X-HMAC-Timestamp']
    
    # Verify timestamp is recent (within 5 minutes)
    unless timestamp.present? && Time.zone.at(timestamp.to_i) > 5.minutes.ago
      return render json: { error: 'Request expired' }, status: :unauthorized
    end

    # Verify signature
    unless signature.present? && valid_signature?(request.raw_post, signature, timestamp)
      return render json: { error: 'Invalid signature' }, status: :unauthorized
    end
    
    true
  end

  def valid_signature?(payload, signature, timestamp)
    secret = ENV['ADMIN_API_HMAC_SECRET']
    data = "#{timestamp}:#{payload}"
    expected_signature = OpenSSL::HMAC.hexdigest('SHA256', secret, data)
    
    ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)
  end
end
