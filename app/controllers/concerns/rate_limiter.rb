module RateLimiter
  extend ActiveSupport::Concern

  class_methods do
    def throttle(to:, within:, only: nil)
      before_action(only: only) do
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
