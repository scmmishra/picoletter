class Newsletters::Settings::ProfileController < ApplicationController
  include NewsletterScoped
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter

  def show; end

  def update
    Current.user.update(profile_params)
    redirect_to settings_profile_path(slug: @newsletter.slug), notice: "Profile successfully updated."
  end

  def destroy_connected_service
    service = Current.user.connected_services.find(params[:id])

    if service.destroy
      redirect_to settings_profile_path(slug: @newsletter.slug), notice: "Successfully disconnected #{service.provider == 'google_oauth2' ? 'Google' : service.provider.titleize}."
    else
      redirect_to settings_profile_path(slug: @newsletter.slug), notice: "Could not disconnect #{service.provider == 'google_oauth2' ? 'Google' : service.provider.titleize}."
    end
  end

  private

  def profile_params
    params.require(:user).permit(:bio, :email, :name)
  end
end
