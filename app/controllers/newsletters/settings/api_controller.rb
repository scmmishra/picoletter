class Newsletters::Settings::ApiController < ApplicationController
  include NewsletterScoped
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action -> { authorize_permission!(:general, :write) }

  def show; end

  def generate_token
    token = nil

    @newsletter.with_lock do
      token = @newsletter.api_tokens.first_or_create!
    end

    if token.previously_new_record?
      redirect_to settings_api_path(slug: @newsletter.slug), notice: "API token generated."
    else
      redirect_to settings_api_path(slug: @newsletter.slug), alert: "A token already exists. Rotate it instead."
    end
  end

  def rotate_token
    token = @newsletter.api_tokens.find(params[:token_id])
    token.regenerate!
    redirect_to settings_api_path(slug: @newsletter.slug), notice: "API token rotated."
  end
end
