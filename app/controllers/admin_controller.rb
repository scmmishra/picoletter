class AdminController < ApplicationController
  before_action :ensure_authenticated, if: :restricted_env?
  before_action :resume_session_if_present, if: :restricted_env?
  before_action :authenticate!, if: :restricted_env?

  private

  def authenticate!
    return if Current.user.super?
    redirect_to auth_login_path, alert: "Please log in to continue."
  end

  def restricted_env?
    Rails.env.staging? || Rails.env.production?
  end
end
