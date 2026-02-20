Rails.application.config.middleware.use OmniAuth::Builder do
  if ENV["GITHUB_CLIENT_ID"].present?
    provider :github, ENV["GITHUB_CLIENT_ID"], ENV["GITHUB_CLIENT_SECRET"], scope: "user:email"
  end

  if ENV["GOOGLE_CLIENT_ID"].present?
    provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"], {
      scope: "email,profile",
      prompt: "select_account"
    }
  end

  # Enable in development only
  provider :developer if Rails.env.development?
end

# Configure OmniAuth to use CSRF protection
OmniAuth.config.allowed_request_methods = [ :post ]

# Handle failure cases
OmniAuth.config.on_failure = Proc.new do |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end
