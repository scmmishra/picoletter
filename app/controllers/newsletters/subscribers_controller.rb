class Newsletters::SubscribersController < ApplicationController
  include NewsletterScoped
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action :set_subscriber, only: [ :show, :update, :destroy, :unsubscribe, :send_reminder ]
  before_action -> { authorize_permission!(:subscribers, :read) }, only: [ :index, :unverified, :unsubscribed, :show ]
  before_action -> { authorize_permission!(:subscribers, :write) }, only: [ :update, :destroy, :unsubscribe, :send_reminder ]

  def index
    list_subscribers("verified")
  end

  def unverified
    list_subscribers("unverified")
  end

  def unsubscribed
    list_subscribers("unsubscribed")
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
    unless @subscriber.unverified?
      redirect_to subscriber_url(@newsletter.slug, @subscriber.id), alert: "Reminders can only be sent to unverified subscribers."
      return
    end

    if @subscriber.reminder_cooldown_active?
      redirect_to subscriber_url(@newsletter.slug, @subscriber.id), alert: "A reminder was already sent recently. Please wait 24 hours between reminders."
      return
    end

    @subscriber.send_reminder
    redirect_to subscriber_url(@newsletter.slug, @subscriber.id), notice: "Reminder sent."
  end

  private

  def list_subscribers(status)
    @status = status
    @pagy, @subscribers = pagy(@newsletter.subscribers
      .order(created_at: :desc)
      .where(status: status), limit: 30)
    render :index
  end

  def set_subscriber
    @subscriber = @newsletter.subscribers.find(params[:id])
  end

  def subscriber_params
    params.require(:subscriber).permit(:email, :full_name, :notes)
  end
end
