class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"
  helper ApplicationHelper

  private

  def notify_address
    "Picoletter Notifications <notifications@#{sending_domain}>"
  end

  def accounts_address
    "Picoletter Accounts <accounts@#{sending_domain}>"
  end

  def support_address
    "Picoletter Support <support@#{sending_domain}>"
  end

  def alerts_address
    "Picoletter Alerts <alerts@#{sending_domain}>"
  end

  def sending_domain
    AppConfig.get("PICO_SENDING_DOMAIN", "picoletter.com")
  end
end
