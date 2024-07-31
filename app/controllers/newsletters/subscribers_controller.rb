class Newsletters::SubscribersController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action :set_subscriber, only: [ :show, :update, :destroy, :unsubscribe, :send_reminder ]


  def index
    page = params[:page] || 0
    status = params[:status] || "verified"

    @subscribers = @newsletter.subscribers
      .order(created_at: :desc)
      .page(page || 0)
      .where(status: status)
      .per(30)
  end

  def show
  end

  def destroy
    @subscriber.destroy!
    redirect_to subscribers_url(@newsletter.slug), notice: "Subscriber deleted successfully"
  end

  def update
    @subscriber.update!(subscriber_params)
    # redirect to show with notice
    redirect_to subscriber_url(@newsletter.slug, @subscriber.id), notice: "Subscriber updated successfully"
  end

  def unsubscribe
    @subscriber.unsubscribe!
    redirect_to subscriber_url(@newsletter.slug, @subscriber.id), notice: "#{@subscriber.display_name} has been unsubscribed."
  end

  def send_reminder
    @subscriber.send_reminder
    redirect_to subscriber_url(@newsletter.slug, @subscriber.id), notice: "Reminder sent."
  end

  private

  def set_subscriber
    @subscriber = @newsletter.subscribers.find(params[:id])
  end

  def subscriber_params
    params.require(:subscriber).permit(:email, :full_name, :notes)
  end

  def set_newsletter
    @newsletter = Current.user.newsletters.from_slug(params[:slug])
    redirect_to newsletter_url(Current.user.newsletters.first.slug) unless @newsletter
  end
end
