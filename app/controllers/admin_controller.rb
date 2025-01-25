class AdminController < ApplicationController
  before_action :resume_session_if_present
  before_action :authenticate!

  private

  def authenticate!
    return if Current.user and Current.user.super?
    head :unauthorized
  end
end
