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

  def update_embedding
    if @newsletter.update(embedding_params)
      redirect_to embedding_settings_path(slug: @newsletter.slug), notice: "Redirect settings updated successfully."
    else
      redirect_to embedding_settings_path(slug: @newsletter.slug), alert: "Failed to update redirect settings."
    end
  end

  # This method is kept for backward compatibility only and redirects to the dedicated BillingController
  def billing
    redirect_to settings_billing_path(slug: @newsletter.slug)
  end

  def destroy_connected_service
    service = Current.user.connected_services.find(params[:id])

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
    params.require(:newsletter).permit(:title, :description, :timezone, :website, :enable_archive, :auto_reminder_enabled)
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

  def embedding_params
    params.require(:newsletter).permit(:redirect_after_subscribe, :redirect_after_confirm)
  end
end
