# Preview all emails at http://localhost:3000/rails/mailers/subscription_mailer
class SubscriptionMailerPreview < ActionMailer::Preview
  def confirmation
    SubscriptionMailer.with(subscriber: Subscriber.last).confirmation
  end
end
