class PostMailer < ApplicationMailer
  def publish
    @post = params[:post]
    @newsletter = @post.newsletter

    subject = @post.title
    from = @newsletter.sending_address || "#{@newsletter.slug}@mail.picoletter.com"
    reply_to = @newsletter.reply_to || @newsletter.user.email

    recipients = @newsletter.subscribers.verified.pluck(:email)
    recipients.each do |recipient|
      mail(to: recipient, subject: subject, from: from, reply_to: reply_to)
    end
  end
end
