class Auth::Omniauth::CallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :github, :google_oauth2 ] # Skip for omniauth callbacks
  before_action :set_auth_hash, only: [ :github, :google_oauth2 ]

  def github
    process_oauth
  end

  def google_oauth2
    process_oauth
  end

  def failure
    if params[:message] == "access_denied"
      flash[:alert] = "You cancelled the sign in process. Please try again."
    else
      flash[:alert] = "There was an issue with the sign in process. Please try again."
    end

    redirect_to auth_login_path
  end

  private

  def set_auth_hash
    @auth_hash = request.env["omniauth.auth"]
  end

  def process_oauth
    # Check if we are already logged in
    if Current.user.present?
      # Add this service to the current user
      ConnectedService.find_or_create_from_auth_hash(@auth_hash, Current.user)
      flash[:notice] = "Successfully connected your #{@auth_hash['provider'].to_s.titleize} account."
      redirect_to_newsletter_home
      return
    end

    # Try to find an existing service or create it with a user
    service = ConnectedService.find_or_create_from_auth_hash(@auth_hash)

    # Start a new session for the user
    start_new_session_for service.user

    # Redirect to the appropriate page
    if service.user.verified?
      redirect_to_newsletter_home
    else
      # If this is a new user, ensure verification happens before proceeding
      service.user.verify! # Auto-verify users who sign in via OAuth
      redirect_to_newsletter_home(notice: "Your account has been created and verified.")
    end
  end
end
