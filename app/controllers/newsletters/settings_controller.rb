class Newsletters::SettingsController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter

  def index; end

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
  def update_sending; end

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

  def profile_params
    params.require(:user).permit(:bio, :email, :name)
  end
end
