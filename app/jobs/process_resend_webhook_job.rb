class ProcessResendWebhookJob < ApplicationJob
  queue_as :default

  def perform(payload)
    @payload = payload.with_indifferent_access
    @email = find_email_log

    event_name = @payload[:type].to_s.gsub(".", "_")

    if self.respond_to?("process_#{event_name}")
      set_subscriber unless @email.subscriber_id.present?
      send("process_#{event_name}")
    end
  end

  def process_email_delivered
    @email.update(status: "delivered", delivered_at: @payload.dig(:data, :created_at))
  end

  def process_email_complained
    @email.update(status: "complained", delivered_at: @payload.dig(:data, :created_at))
    @email.subscriber.update(unsubscribed_at: @payload.dig(:data, :created_at), status: :unsubscribed, unsubscribe_reason: :complained)
  end

  def process_email_bounced
    @email.update(status: "bounced", delivered_at: @payload.dig(:data, :created_at))
    # if bounced more than 3 times, unsubscribe the subscriber
    bounce_count = Email.where(subscriber: @email.subscriber).bounced.count
    @email.subscriber.update(unsubscribed_at: @payload.dig(:data, :created_at), status: :unsubscribed, unsubscribe_reason: :bounced) if bounce_count >= 3
  end

  private

  def set_subscriber
    subscriber = find_subscriber
    @email.update(subscriber: subscriber)
    @email.reload
  end

  def find_email_log
    Email.find_by(email_id: @payload.dig(:data, :email_id))
  end

  def find_subscriber
    to_emails = @payload.dig(:data, :to)
    Subscriber.find_by(email: to_emails.first)
  end
end
