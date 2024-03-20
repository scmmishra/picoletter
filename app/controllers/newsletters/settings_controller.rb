class Newsletters::SettingsController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter

  def index; end

  def update; end

  private

  def set_newsletter
    @newsletter = Newsletter.find_by(slug: params[:slug])
  end
end
