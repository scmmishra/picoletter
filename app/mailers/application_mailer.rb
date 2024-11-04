class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"

  private

  def notify_address
    "Picoletter Notifications <notify@#{sending_domain}>"
  end

  def accounts_address
    "Picoletter Accounts <accounts@#{sending_domain}>"
  end

  def support_address
    "Picoletter Support <accounts@#{sending_domain}>"
  end

  def no_reply_address
    "Picoletter <accounts@#{sending_domain}>"
  end

  def sending_domain
    AppConfig.get("APP_SENDING_DOMAIN", "picoletter.com")
  end
end
