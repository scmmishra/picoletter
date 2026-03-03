class ProcessSNSWebhookJob < ApplicationJob
  include HTTParty
  queue_as :default

  def perform(payload)
    # https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-examples.html
    @payload = payload.with_indifferent_access

    if @payload[:Type] == "SubscriptionConfirmation"
      process_subscription_confirmation
      return
    end
    unless @payload[:Type] == "Notification"
      Rails.logger.info("[ProcessSNSWebhookJob] Ignored SNS payload with unsupported type #{@payload[:Type].inspect}")
      return
    end

    @message = parse_notification_message(@payload[:Message])
    return unless @message.present?

    message_id = @message.dig(:mail, :messageId)
    if message_id.blank?
      Rails.logger.info("[ProcessSNSWebhookJob] Ignored SNS notification without mail.messageId")
      return
    end

    @email = Email.find_by(id: message_id)
    return unless @email.present?

    event_name = @message[:eventType].to_s.underscore
    if event_name.blank?
      Rails.logger.info("[ProcessSNSWebhookJob] Ignored SNS notification without eventType")
      return
    end
    Rails.logger.info "[ProcessSNSWebhookJob] Processing #{event_name} event for email #{@email.id}"

    case event_name
    when "bounce"    then process_bounce
    when "complaint" then process_complaint
    when "delivery"  then process_delivery
    when "click"     then process_click
    when "open"      then process_open
    end

    @email.emailable.clear_stats_cache if @email.emailable_type == "Post"
  end

  def parse_notification_message(message)
    parsed_message = JSON.parse(message.to_s)
    return parsed_message.with_indifferent_access if parsed_message.is_a?(Hash)

    Rails.logger.info("[ProcessSNSWebhookJob] Ignored SNS notification with non-object Message payload")
    nil
  rescue JSON::ParserError
    Rails.logger.info("[ProcessSNSWebhookJob] Ignored SNS notification with non-JSON Message payload")
    nil
  end

  def process_subscription_confirmation
    data = @payload[:SubscribeURL]
    unless SNSMessageVerifier.valid_subscription_confirmation_url?(data)
      Rails.logger.warn("[ProcessSNSWebhookJob] Ignored invalid SNS SubscribeURL")
      return
    end

    HTTParty.get(data)
  end

  def process_bounce
    data = @message[:bounce]
    timestamp = data.dig(:timestamp)
    @email.update(status: "bounced", bounced_at: timestamp)
    bounce_count = Email.where(subscriber: @email.subscriber).bounced.count
    @email.subscriber.unsubscribe_with_reason!("bounced") if bounce_count >= 2
  end

  def process_complaint
    data = @message[:complaint]
    timestamp = data.dig(:timestamp)

    @email.update(status: "complained", complained_at: timestamp)
    @email.subscriber.unsubscribe_with_reason!("complained")
  end

  def process_delivery
    data = @message[:delivery]
    timestamp = data.dig(:timestamp)

    @email.update(status: "delivered", delivered_at: timestamp)
  end

  def process_click
    return unless @email.emailable_type == "Post"

    data = @message[:click]
    timestamp = data.dig(:timestamp)
    link = data.dig(:link)

    return if @email.clicks.exists?(link: link, post_id: @email.emailable_id)
    @email.clicks.create(link: link, timestamp: timestamp, post_id: @email.emailable_id)
  end

  def process_open
    data = @message[:open]
    timestamp = data.dig(:timestamp)

    @email.update(opened_at: timestamp)
  end
end
