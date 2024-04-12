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
    @newsletter.update(sending_params)
    redirect_to sending_settings_url(slug: @newsletter.slug), notice: "Settings successfully updated."
  end

  def verify_domain
    @newsletter.verify_custom_domain
    notice = @newsletter.domain_verified ? "Domain successfully verified." : "Waiting for domain verification."
    redirect_to sending_settings_url(slug: @newsletter.slug), notice: notice
  end

  def signup_flow; end
  def update_signup_flow
  end

  private

  def set_newsletter
    @newsletter = Newsletter.find_by(slug: params[:slug])
  end

  def newsletter_params
    params.require(:newsletter).permit(:title, :description, :timezone, :website)
  end

  def design_params
    params.require(:newsletter).permit(:email_css, :email_footer, :font_preference, :primary_color)
  end

  def sending_params
    params.require(:newsletter).permit(:reply_to, :domain, :sending_address, :use_custom_domain)
  end

  def profile_params
    params.require(:user).permit(:bio, :email, :name)
  end
end
