class Newsletters::Settings::ApiController < ApplicationController
  include NewsletterScoped
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action -> { authorize_permission!(:general, :write) }

  def show; end

  def generate_token
    if @newsletter.api_tokens.exists?
      redirect_to settings_api_path(slug: @newsletter.slug), alert: "A token already exists. Rotate it instead."
      return
    end

    @newsletter.api_tokens.create!
    redirect_to settings_api_path(slug: @newsletter.slug), notice: "API token generated."
  end

  def rotate_token
    token = @newsletter.api_tokens.find(params[:token_id])
    token.regenerate!
    redirect_to settings_api_path(slug: @newsletter.slug), notice: "API token rotated."
  end
end
