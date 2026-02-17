module NewsletterScoped
  extend ActiveSupport::Concern

  private

  def set_newsletter
    @newsletter = Current.user.newsletters.from_slug(params[:slug])
    return if @newsletter

    redirect_to_newsletter_home(notice: "You do not have access to this newsletter.")
  end
end
