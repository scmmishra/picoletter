class Newsletters::Settings::BillingController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter

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
end