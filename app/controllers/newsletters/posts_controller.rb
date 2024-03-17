class Newsletters::PostsController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action :set_post, only: [ :show, :edit, :publish, :destroy, :update ]

  def index
    @posts = @newsletter.posts.published.order(published_at: :desc)
  end

  def drafts
    @posts = @newsletter.posts.drafts.order(updated_at: :desc)
  end

  def archive
    @posts = @newsletter.posts.archived.order(updated_at: :desc)
  end

  def show; end

  def edit; end

  def update
    @post.update(post_params)
    # redirect_to edit_post_url(slug: @newsletter.slug, id: @post.id), notice: "Post was successfully updated."
  end

  def new
    @post = @newsletter.posts.new
  end

  def create
    @post = @newsletter.posts.new(post_params)
    if @post.save
      redirect_to edit_post_url(slug: @newsletter.slug, id: @post.id), notice: "Post was successfully created."
    end
  end

  def publish
    @post.publish
    redirect_to post_url(slug: @newsletter.slug, id: @post.id), notice: "Post was successfully published."
  end

  def destroy
    @post.destroy
    redirect_to drafts_posts_url(slug: @newsletter.slug), notice: "Post deleted successfully."
  end

  private

  def set_newsletter
    @newsletter = Current.user.newsletters.from_slug(params[:slug])
    redirect_to newsletter_url(Current.user.newsletters.first.slug) unless @newsletter
  end

  def set_post
    @post = @newsletter.posts.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :content)
  end
end
