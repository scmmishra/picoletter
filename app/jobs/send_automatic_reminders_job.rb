class SendAutomaticRemindersJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = AppConfig.get("REMINDER_BATCH_SIZE", 50)

  def perform
    return unless AppConfig.get("ENABLE_AUTO_REMINDERS", false)

    eligible_subscriber_ids = Subscriber.eligible_for_reminder.limit(BATCH_SIZE).pluck(:id)

    Rails.logger.info("[SendAutomaticRemindersJob] Processing #{eligible_subscriber_ids.count} eligible subscribers")

    success_count = 0
    error_count = 0

    eligible_subscriber_ids.each do |subscriber_id|
      Subscriber.claim_for_reminder(subscriber_id) do |subscriber|
        begin
          subscriber.send_reminder
          subscriber.record_reminder_sent!
          success_count += 1
          Rails.logger.debug("[SendAutomaticRemindersJob] Sent reminder to subscriber #{subscriber.id}")
        rescue StandardError => e
          error_count += 1
          Rails.logger.error("[SendAutomaticRemindersJob] Failed to send reminder to subscriber #{subscriber.id}: #{e.message}")
          RorVsWild.record_error(e, context: { subscriber_id: subscriber.id })
        end
      end
    end

    Rails.logger.info("[SendAutomaticRemindersJob] Completed: #{success_count} sent, #{error_count} failed")
  end
end
