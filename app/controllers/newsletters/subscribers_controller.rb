class Newsletters::SubscribersController < ApplicationController
  before_action :ensure_authenticated
  before_action :set_newsletter

  def index
    @subscribers = @newsletter.subscribers.all
  end

  private

  def set_newsletter
    @newsletter = Current.user.newsletters.from_slug(params[:slug])
    redirect_to newsletter_url(Current.user.newsletters.first.slug) unless @newsletter
  end
end
