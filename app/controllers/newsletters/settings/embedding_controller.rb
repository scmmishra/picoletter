class Newsletters::Settings::EmbeddingController < ApplicationController
  include NewsletterScoped
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter

  def show; end

  def update
    if @newsletter.update(embedding_params)
      redirect_to settings_embedding_path(slug: @newsletter.slug), notice: "Redirect settings updated successfully."
    else
      redirect_to settings_embedding_path(slug: @newsletter.slug), alert: "Failed to update redirect settings."
    end
  end

  private

  def embedding_params
    params.require(:newsletter).permit(:redirect_after_subscribe, :redirect_after_confirm)
  end
end
