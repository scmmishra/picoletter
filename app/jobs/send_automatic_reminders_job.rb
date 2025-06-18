class SendAutomaticRemindersJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = ENV.fetch("REMINDER_BATCH_SIZE", 50).to_i

  def perform
    eligible_subscriber_ids = Subscriber.eligible_for_reminder.limit(BATCH_SIZE).pluck(:id)

    Rails.logger.info("[SendAutomaticRemindersJob] Processing #{eligible_subscriber_ids.count} eligible subscribers")

    success_count = 0
    error_count = 0

    eligible_subscriber_ids.each do |subscriber_id|
      subscriber = Subscriber.claim_for_reminder(subscriber_id)
      next unless subscriber

      begin
        subscriber.send_reminder
        subscriber.record_reminder_sent!
        success_count += 1
        Rails.logger.debug("[SendAutomaticRemindersJob] Sent reminder to subscriber #{subscriber.id}")
      rescue StandardError => e
        # Clear processing flag on failure so it can be retried
        subscriber.update!(
          additional_data: subscriber.additional_data.except("processing_reminder_at")
        )
        error_count += 1
        Rails.logger.error("[SendAutomaticRemindersJob] Failed to send reminder to subscriber #{subscriber.id}: #{e.message}")
        Rails.error.report(e, context: { subscriber_id: subscriber.id })
      end
    end

    Rails.logger.info("[SendAutomaticRemindersJob] Completed: #{success_count} sent, #{error_count} failed")
  end
end
