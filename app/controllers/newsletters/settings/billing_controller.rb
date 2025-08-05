class Newsletters::Settings::BillingController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action -> { authorize_permission!(:billing) }

  def show
    # Display billing page
  end

  def checkout
    redirect_to Current.user.billing_checkout_url, allow_other_host: true
  end

  def manage
    redirect_to Current.user.billing_manage_url, allow_other_host: true
  end

  private

  def set_newsletter
    @newsletter = Newsletter.find_by(slug: params[:slug])
  end

  def authorize_permission!(permission)
    unless @newsletter.can_access?(permission)
      redirect_to profile_settings_path(slug: @newsletter.slug), 
                  alert: "You don't have permission to access that section."
    end
  end
end
