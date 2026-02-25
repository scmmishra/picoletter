class SendSubscriberReminderJob < ApplicationJob
  queue_as :default

  def perform(subscriber_id, kind:)
    @subscriber = Subscriber.find(subscriber_id)
    @newsletter = @subscriber.newsletter

    confirmation_url = generate_confirmation_url
    subject = "Reminder: Confirm your subscription to #{@newsletter.title}"

    html_content = render_html(confirmation_url)
    text_content = render_text(confirmation_url)

    response = send_email(subject, html_content, text_content)

    reminder = @subscriber.reminders.create!(
      kind: kind,
      message_id: response.message_id,
      sent_at: Time.current
    )

    reminder.emails.create!(
      id: response.message_id,
      subscriber: @subscriber
    )
  rescue StandardError => e
    Rails.error.report(e, context: { subscriber_id: subscriber_id, kind: kind }, handled: false)
    raise
  end

  private

  def generate_confirmation_url
    token = @subscriber.generate_token_for(:confirmation)
    Rails.application.routes.url_helpers.confirm_url(slug: @newsletter.slug, token: token)
  end

  def render_html(confirmation_url)
    ApplicationController.render(
      template: "subscription_mailer/confirmation_reminder",
      assigns: { subscriber: @subscriber, newsletter: @newsletter, confirmation_url: confirmation_url },
      layout: "newsletter_mailer",
      formats: [ :html ]
    )
  end

  def render_text(confirmation_url)
    ApplicationController.render(
      template: "subscription_mailer/confirmation_reminder",
      assigns: { subscriber: @subscriber, newsletter: @newsletter, confirmation_url: confirmation_url },
      layout: false,
      formats: [ :text ]
    )
  end

  def send_email(subject, html_content, text_content)
    ses_service = SES::EmailService.new
    ses_service.send(
      to: [ @subscriber.email ],
      from: @newsletter.full_sending_address,
      reply_to: @newsletter.reply_to.presence || @newsletter.user.email,
      subject: subject,
      html: html_content,
      text: text_content,
      headers: {
        "X-Newsletter-id" => "picoletter-reminder-#{@newsletter.id}-#{@subscriber.id}"
      }
    )
  end
end
