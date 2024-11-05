class ProcessSNSWebhookJob < ApplicationJob
  include HTTParty
  queue_as :default

  def perform(payload)
    # https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-examples.html
    @payload = payload.with_indifferent_access

    if @payload[:Type] === "SubscriptionConfirmation"
      process_subscription_confirmation
      return
    end

    @message = JSON.parse(@payload[:Message]).with_indifferent_access
    @email = Email.find_by(id: @message[:mail][:messageId])
    return unless @email.present?

    event_name = @message[:eventType].underscore
    if self.respond_to?("process_#{event_name}")
      send("process_#{event_name}")
    end
  end

  def process_subscription_confirmation
    data = @payload[:SubscribeURL]
    response = HTTParty.get(data)
  end

  def process_bounce
    data = @message[:bounce]
    timestamp = data.dig(:timestamp)
    @email.update(status: "bounced", bounced_at: timestamp)
    bounce_count = Email.where(subscriber: @email.subscriber).bounced.count
    @email.subscriber.unsubscrib_with_reason!("Email bounced") if bounce_count >= 3
  end

  def process_complaint
    data = @message[:complaint]
    timestamp = data.dig(:timestamp)

    @email.update(status: "complained", complained_at: timestamp)
    @email.subscriber.unsubscrib_with_reason!("Email complained")
  end

  def process_delivery
    data = @message[:delivery]
    timestamp = data.dig(:timestamp)

    @email.update(status: "delivered", delivered_at: timestamp)
  end

  def process_click
    data = @message[:click]
    timestamp = data.dig(:timestamp)
    link = data.dig(:link)

    return if @email.clicks.exists?(link: link)
    @email.clicks.create(link: link, timestamp: timestamp)
  end

  def process_open
    data = @message[:open]
    timestamp = data.dig(:timestamp)

    @email.update(opened_at: timestamp)
  end
end
