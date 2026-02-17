module NewsletterScoped
  extend ActiveSupport::Concern

  private

  def set_newsletter
    @newsletter = Current.user.newsletters.from_slug(params[:slug])
    return if @newsletter

    redirect_to_newsletter_home(notice: "You do not have access to this newsletter.")
  end

  def authorize_permission!(permission, access_type = :read)
    unless @newsletter.can_access?(permission, access_type)
      redirect_to profile_settings_path(slug: @newsletter.slug),
                  alert: "You don't have permission to access that section."
    end
  end
end
