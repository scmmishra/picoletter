# Preview all emails at http://localhost:3000/rails/mailers/subscription_mailer
class SubscriptionMailerPreview < ActionMailer::Preview
  def confirmation
    SubscriptionMailer.with(subscriber: Subscriber.last).confirmation
  end

  def confirmation_reminder
    SubscriptionMailer.with(subscriber: Subscriber.last).confirmation_reminder
  end
end
