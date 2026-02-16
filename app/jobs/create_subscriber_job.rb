class CreateSubscriberJob < ApplicationJob
  queue_as :default

  def perform(newsletter_id, email, name, labels, created_via, analytics_data = {})
    newsletter = Newsletter.find(newsletter_id)
    split_labels = labels&.split(",")&.map(&:strip) || []

    # Verify email and MX record
    verified = VerifyEmailService.new(email).verify

    Rails.logger.info("[CreateSubscriberJob] Email verification for #{email}: #{verified}")

    unless verified
      Rails.logger.error("[CreateSubscriberJob] Invalid email or MX record for #{email}")
      return false
    end

    subscriber = newsletter.subscribers.find_or_initialize_by(email: email)
    subscriber.full_name = name if name.present?
    subscriber.labels = split_labels
    subscriber.created_via = created_via
    subscriber.analytics_data = analytics_data
    subscriber.save!

    subscriber.send_confirmation_email unless subscriber.verified?
    true
  end
end
