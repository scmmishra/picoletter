class ProcessSNSWebhookJob < ApplicationJob
  queue_as :default

  def perform(payload)
    # https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-examples.html
    @payload = payload.with_indifferent_access
    @email = Email.find_by!(email_id: payload[:mail][:messageId])
    event_name = payload[:eventType].underscore

    if self.respond_to?("process_#{event_name}")
      send("process_#{event_name}")
    end
  end

  private

  def process_bounce
    data = @payload[:bounce]
    timestamp = data.dig(:timestamp)
    @email.update(status: "bounced", bounced_at: timestamp)
    bounce_count = Email.where(subscriber: @email.subscriber).bounced.count
    @email.subscriber.unsubscrib_with_reason!("Email bounced") if bounce_count >= 3
  end

  def process_complaint
    data = @payload[:complaint]
    timestamp = data.dig(:timestamp)

    @email.update(status: "complained", complained_at: timestamp)
    @email.subscriber.unsubscrib_with_reason!("Email complained")
  end

  def process_delivery
    data = @payload[:delivery]
    timestamp = data.dig(:timestamp)

    @email.update(status: "delivered", delivered_at: timestamp)
  end

  def process_open
    data = @payload[:open]
    timestamp = data.dig(:timestamp)

    @email.update(opened_at: timestamp)
  end
end
