class SendAutomaticRemindersJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = AppConfig.get("REMINDER_BATCH_SIZE", 100)

  def perform
    return unless AppConfig.get("ENABLE_AUTO_REMINDERS", false)

    success_count = 0
    error_count = 0

    # Process all eligible subscribers in batches to avoid memory issues
    Subscriber.eligible_for_reminder.find_in_batches(batch_size: BATCH_SIZE) do |subscribers_batch|
      Rails.logger.info("[SendAutomaticRemindersJob] Processing batch of #{subscribers_batch.size} eligible subscribers")

      subscribers_batch.each do |subscriber|
        Subscriber.claim_for_reminder(subscriber.id) do |claimed_subscriber|
          begin
            claimed_subscriber.send_reminder
            claimed_subscriber.record_reminder_sent!
            success_count += 1
            Rails.logger.debug("[SendAutomaticRemindersJob] Sent reminder to subscriber #{claimed_subscriber.id}")
          rescue StandardError => e
            error_count += 1
            Rails.logger.error("[SendAutomaticRemindersJob] Failed to send reminder to subscriber #{claimed_subscriber.id}: #{e.message}")
            RorVsWild.record_error(e, context: { subscriber_id: claimed_subscriber.id })
          end
        end
      end
    end

    Rails.logger.info("[SendAutomaticRemindersJob] Completed: #{success_count} sent, #{error_count} failed")
  end
end
