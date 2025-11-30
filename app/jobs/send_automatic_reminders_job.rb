# This job is triggered every 30 minutes to send automatic reminders to unverified subscribers
# who signed up approximately 24 hours ago and haven't received any reminder yet.
class SendAutomaticRemindersJob < ApplicationJob
  queue_as :default

  def perform
    unless AppConfig.reminders_enabled?
      Rails.logger.info "[SendAutomaticReminders] Reminders feature is disabled"
      return
    end

    Rails.logger.info "[SendAutomaticReminders] Starting automatic reminder processing"

    Newsletter.where(auto_reminder_enabled: true).find_each do |newsletter|
      process_newsletter(newsletter)
    end

    Rails.logger.info "[SendAutomaticReminders] Completed automatic reminder processing"
  end

  private

  def process_newsletter(newsletter)
    newsletter.subscribers.eligible_for_auto_reminder.find_each do |subscriber|
      next if subscriber.has_delivery_issues?

      Rails.logger.info "[SendAutomaticReminders] Sending reminder to subscriber #{subscriber.id} for newsletter #{newsletter.id}"
      subscriber.send_reminder(kind: :automatic)
    rescue StandardError => e
      RorVsWild.record_error(e, context: { subscriber_id: subscriber.id, newsletter_id: newsletter.id })
      Rails.logger.error "[SendAutomaticReminders] Error for subscriber #{subscriber.id}: #{e.message}"
    end
  end
end
