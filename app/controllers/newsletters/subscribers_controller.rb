class Newsletters::SubscribersController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated, only: [ :index ]
  before_action :set_newsletter


  def index
    page = params[:page] || 0
    status = params[:status] || "verified"

    @subscribers = @newsletter.subscribers
      .order(created_at: :desc)
      .page(page || 0)
      .where(status: status)
      .per(30)
  end

  private

  def set_newsletter
    @newsletter = Current.user.newsletters.from_slug(params[:slug])
    redirect_to newsletter_url(Current.user.newsletters.first.slug) unless @newsletter
  end
end
