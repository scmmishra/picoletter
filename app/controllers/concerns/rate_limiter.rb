module RateLimiter
  extend ActiveSupport::Concern

  class_methods do
    def throttle(to:, within:, only: nil, block_bots: false)
      before_action(only: only) do
        Rails.logger.info "[RateLimiter] Rate limiting #{controller_name}##{action_name} for #{request.remote_ip}"

        if Rails.env.production?
          if block_bots && bot?
            Rails.logger.info "[RateLimiter] Bot access denied for #{request.remote_ip}"
            render plain: "Access denied", status: :forbidden
            return
          end

          # use remote_ip to rate limit by IP address
          key = "rate_limit:#{request.remote_ip}:#{controller_name}:#{action_name}"
          count = Rails.cache.increment(key, 1, expires_in: within)

          if count > to
            render plain: "Rate limit exceeded", status: :too_many_requests
          end
        end
      end
    end
  end

  private

  def bot?
    browser = Browser.new(request.user_agent)
    browser.bot?
  end
end
