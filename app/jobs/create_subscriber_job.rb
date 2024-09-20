class CreateSubscriberJob < ApplicationJob
  queue_as :default

  def perform(newsletter_id, email, name, created_via, analytics_data = {})
    newsletter = Newsletter.find(newsletter_id)

    # Verify email and MX record
    verified = VerifyEmailService.new(email).verify

    Rails.logger.info("[CreateSubscriberJob] Email verification for #{email}: #{verified}")

    if verified && mx_verified
      subscriber = newsletter.subscribers.find_or_initialize_by(email: email)
      subscriber.full_name = name if name.present?
      subscriber.created_via = created_via
      subscriber.analytics_data = analytics_data
      subscriber.save!

      subscriber.send_confirmation_email unless subscriber.verified?
    else
      Rails.logger.error("[CreateSubscriberJob] Invalid email or MX record for #{email}")
    end
  end
end
