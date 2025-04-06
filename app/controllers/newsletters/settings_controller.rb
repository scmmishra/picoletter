class Newsletters::SettingsController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter

  def show; end

  def update
    @newsletter.update(newsletter_params)
    redirect_to settings_url(slug: @newsletter.slug), notice: "Newsletter successfully updated."
  end

  def profile; end

  def update_profile
    Current.user.update(profile_params)
    redirect_to profile_settings_url, notice: "Profile successfully updated."
  end

  def design; end

  def update_design
    @newsletter.update(design_params)
    redirect_to design_settings_url(slug: @newsletter.slug), notice: "Design successfully updated."
  end

  def sending; end

  def update_sending
    DomainSetupService.new(@newsletter, sending_params).perform
    redirect_to sending_settings_url(slug: @newsletter.slug), notice: "Settings successfully updated."
  rescue StandardError => e
    RorVsWild.record_error(e, context: { params: sending_params, newsletter_id: @newsletter.id })
    redirect_to sending_settings_url(slug: @newsletter.slug), alert: e.message
  end

  def verify_domain
    @newsletter.verify_custom_domain
    notice = @newsletter.ses_verified? ? "Domain successfully verified." : "Waiting for domain verification."
    redirect_to sending_settings_url(slug: @newsletter.slug), notice: notice
  end

  def embedding; end
  def update_embedding; end

  def billing; end

  def destroy_connected_service
    service = Current.user.connected_services.find(params[:id])

    # Prevent deletion of the last authentication method if no password is set
    if Current.user.connected_services.count == 1 && Current.user.password_digest.blank?
      redirect_to profile_settings_path(slug: @newsletter.slug), notice: "You cannot remove your last login method. Please set a password first."
      return
    end

    if service.destroy
      redirect_to profile_settings_path(slug: @newsletter.slug), notice: "Successfully disconnected #{service.provider == 'google_oauth2' ? 'Google' : service.provider.titleize}."
    else
      redirect_to profile_settings_path(slug: @newsletter.slug), notice: "Could not disconnect #{service.provider == 'google_oauth2' ? 'Google' : service.provider.titleize}."
    end
  end

  private

  def set_newsletter
    @newsletter = Newsletter.find_by(slug: params[:slug])
  end

  def newsletter_params
    params.require(:newsletter).permit(:title, :description, :timezone, :website, :enable_archive)
  end

  def design_params
    params.require(:newsletter).permit(:email_css, :email_footer, :font_preference, :primary_color)
  end

  def sending_params
    params.require(:newsletter).permit(:reply_to, :sending_address, :sending_name)
  end

  def profile_params
    params.require(:user).permit(:bio, :email, :name)
  end
end
