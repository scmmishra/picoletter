class Newsletters::SettingsController < ApplicationController
  include NewsletterScoped
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action -> { authorize_permission!(:general, :read) }, only: [ :show ]
  before_action -> { authorize_permission!(:general, :write) }, only: [ :update, :api, :generate_token, :rotate_token ]
  before_action -> { authorize_permission!(:design, :read) }, only: [ :design ]
  before_action -> { authorize_permission!(:design, :write) }, only: [ :update_design ]
  before_action -> { authorize_permission!(:sending, :read) }, only: [ :sending ]
  before_action -> { authorize_permission!(:sending, :write) }, only: [ :update_sending, :verify_domain ]
  before_action -> { authorize_permission!(:billing, :read) }, only: [ :billing ]

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
    Rails.error.report(e, context: { params: sending_params, newsletter_id: @newsletter.id })
    redirect_to sending_settings_url(slug: @newsletter.slug), alert: e.message
  end

  def verify_domain
    @newsletter.verify_custom_domain
    notice = @newsletter.ses_verified? ? "Domain successfully verified." : "Waiting for domain verification."
    redirect_to sending_settings_url(slug: @newsletter.slug), notice: notice
  end

  def api; end

  def embedding; end

  def generate_token
    if @newsletter.api_tokens.exists?
      redirect_to api_settings_url(slug: @newsletter.slug), alert: "A token already exists. Rotate it instead."
      return
    end

    @newsletter.api_tokens.create!
    redirect_to api_settings_url(slug: @newsletter.slug), notice: "API token generated."
  end

  def rotate_token
    token = @newsletter.api_tokens.find(params[:token_id])
    token.regenerate!
    redirect_to api_settings_url(slug: @newsletter.slug), notice: "API token rotated."
  end

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



  def newsletter_params
    params.require(:newsletter).permit(:title, :description, :timezone, :website, :enable_archive, :auto_reminder_enabled)
  end

  def design_params
    params.require(:newsletter).permit(:email_css, :email_footer, :font_preference, :primary_color, :template)
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
