class Newsletters::PostsController < ApplicationController
  layout "newsletters"

  include NewsletterScoped

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action :set_last_opened, only: [ :index ]
  before_action :set_post, only: [ :show, :edit, :publish, :destroy, :update, :schedule, :unschedule, :send_test ]

  rate_limit to: 10, within: 30.minute, only: :send_test

  def index
    @posts = @newsletter.posts.published.order(published_at: :desc)
  end

  def drafts
    @posts = @newsletter.posts.drafts_and_processing.order(updated_at: :desc)
  end

  def archive
    @posts = @newsletter.posts.archived.order(updated_at: :desc)
  end

  def show; end

  def edit; end

  def update
    if @post.update(post_params)
      respond_to do |format|
        format.html { redirect_to edit_post_url(slug: @newsletter.slug, id: @post.id), notice: "Post was successfully updated." }
        format.json { render json: { content: @post.content.to_s, title: @post.title } }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json { render json: { errors: @post.errors }, status: :unprocessable_entity }
      end
    end
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

  def schedule
    utc_schedule = parse_utc_schedule(schedule_params[:scheduled_at_epoch_ms])

    @post.schedule(utc_schedule)
    redirect_to edit_post_url(slug: @newsletter.slug, id: @post.id), notice: "Post was successfully scheduled."
  rescue => e
    Rails.error.report(e, context: { params: params[:post] })
    redirect_to edit_post_url(slug: @newsletter.slug, id: @post.id), notice: "Something went wrong while publishing the post"
  end

  def unschedule
    @post.unschedule
    redirect_to edit_post_url(slug: @newsletter.slug, id: @post.id), notice: "Post was successfully unscheduled."
  end

  def publish
    no_verify = params[:no_verify] == "true"

    @post.with_lock do
      unless @post.draft?
        redirect_to post_url(slug: @newsletter.slug, id: @post.id),
                   notice: "Post already published." and return
      end

      @post.publish_and_send(no_verify)
    end

    redirect_to post_url(slug: @newsletter.slug, id: @post.id), notice: "Post was successfully published."
  rescue Exceptions::LimitExceedError => e
    redirect_to edit_post_url(slug: @newsletter.slug, id: @post.id), notice: "Sending this will exceed sending limits. Please upgrade to continue"
  rescue Exceptions::SubscriptionError => e
    redirect_to edit_post_url(slug: @newsletter.slug, id: @post.id), notice: "You need an active subscription to send this post."
  rescue Exceptions::InvalidLinkError => e
    Rails.logger.error("Error sending post: #{e.message}")
    flash[:has_link_error] = true
    redirect_to edit_post_url(slug: @newsletter.slug, id: @post.id), notice: "We found invalid links in your post."
  rescue StandardError => e
    Rails.error.report(e)
    Rails.logger.error("Error sending post: #{e.message}")
    redirect_to edit_post_url(slug: @newsletter.slug, id: @post.id), notice: e.message
  end

  def send_test
    @post.send_test_email(Current.user.email)
    redirect_to edit_post_url(slug: @newsletter.slug, id: @post.id), notice: "Test post sent to #{Current.user.email}"
  end

  def destroy
    @post.destroy
    redirect_to drafts_posts_url(slug: @newsletter.slug), notice: "Post deleted successfully."
  end


  private

  def set_last_opened
    Rails.cache.write("last_opened_newsletter_#{Current.user.id}", @newsletter.slug)
  end


  def set_post
    @post = @newsletter.posts.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :content)
  end

  def schedule_params
    params.require(:post).permit(:scheduled_at_epoch_ms)
  end

  def parse_utc_schedule(epoch_ms_value)
    raise ArgumentError, "scheduled_at_epoch_ms is required" if epoch_ms_value.blank?

    epoch_ms = Integer(epoch_ms_value, 10)
    Time.at(epoch_ms / 1000.0).utc
  end
end
