class Public::NewslettersController < ApplicationController
  before_action :set_newsletter
  before_action :set_post, only: [ :show_post ]

  def show
  end

  def show_post
  end

  private

  def set_post
    @post = @newsletter.posts.published.from_slug(params[:post_slug])

    raise ActiveRecord::RecordNotFound if @post.nil?
  end

  def set_newsletter
    @newsletter = Newsletter.from_slug(params[:slug])

    raise ActiveRecord::RecordNotFound if @newsletter.nil?
  end
end
