class Public::NewslettersController < ApplicationController
  include ActiveHashcash

  layout "public"
  before_action :set_newsletter
  before_action :set_newsletter_layout
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

    head :not_found unless @post
  end

  def set_newsletter
    @newsletter = Newsletter.from_slug(params[:slug])

    head :not_found unless @newsletter
  end

  def set_newsletter_layout
    # get the description as plain text, if
    # it is 500 characters or less use vertical, or else horizontal
    return "vertical" unless @newsletter.description.present?

    @newsletter_layout = @newsletter.description&.length > 500 ? "horizontal" : "vertical"
  end
end
