class AdminMailer < ApplicationMailer
  layout "base_mailer"
  def stuck_posts_alert(stuck_posts)
    @stuck_posts = stuck_posts
    @stuck_count = stuck_posts.count

    # Get all super admin emails
    admin_emails = User.where(is_superadmin: true).pluck(:email)

    # Restrict fallback email to development/test environments
    if admin_emails.empty?
      if Rails.env.development? || Rails.env.test?
        admin_emails = [ "admin@example.com" ]
      else
        raise "No super admin emails configured. Cannot send stuck posts alert."
      end
    end
    mail(
      to: admin_emails,
      subject: "[Picoletter Alert] #{@stuck_count} stuck post(s) detected",
      from: alerts_address
    )
  end
end
