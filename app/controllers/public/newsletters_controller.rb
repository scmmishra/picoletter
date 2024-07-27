class Public::NewslettersController < ApplicationController
  layout "public"
  before_action :set_newsletter
  before_action :set_post, only: [ :show_post ]
  before_action :ensure_archive_enabled, only: [ :show_post, :all_posts ]

  def show
    fresh_when(@newsletter)
  end

  def show_post
    fresh_when(@post, public: true)
  end

  def all_posts
    @posts = @newsletter.posts.published
  end

  private

  def ensure_archive_enabled
    redirect_to newsletter_url(@newsletter.slug) unless @newsletter.enable_archive
  end

  def set_post
    @post = @newsletter.posts.published.from_slug(params[:post_slug])

    raise ActiveRecord::RecordNotFound if @post.nil?
  end

  def set_newsletter
    @newsletter = Newsletter.from_slug(params[:slug])

    raise ActiveRecord::RecordNotFound if @newsletter.nil?
  end
end
