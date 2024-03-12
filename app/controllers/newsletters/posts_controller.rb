class Newsletters::PostsController < ApplicationController
  before_action :ensure_authenticated
  before_action :set_newsletter

  def index
    @posts = @newsletter.posts.published.order(:published_at)
  end

  def drafts
    @posts = @newsletter.posts.drafts.order(:updated_at)
  end

  def archive
    @posts = @newsletter.posts.archived.order(:updated_at)
  end

  private

  def set_newsletter
    @newsletter = Current.user.newsletters.from_slug(params[:slug])
    redirect_to newsletter_url(Current.user.newsletters.first.slug) unless @newsletter
  end
end
