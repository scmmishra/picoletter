class AdminMailer < ApplicationMailer
  layout "base_mailer"
  def stuck_posts_alert(stuck_posts)
    @stuck_posts = stuck_posts
    @stuck_count = stuck_posts.count

    # Get all super admin emails
    admin_emails = User.where(is_superadmin: true).pluck(:email)

    # For preview, use a default email if no admins exist
    admin_emails = [ "admin@example.com" ] if admin_emails.empty?

    mail(
      to: admin_emails,
      subject: "[Picoletter Alert] #{@stuck_count} stuck post(s) detected",
      from: alerts_address
    )
  end
end
