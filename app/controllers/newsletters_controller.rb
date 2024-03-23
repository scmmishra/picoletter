class NewslettersController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated

  def index
    @newsletters = Current.user.newsletters.all
  end

  def show
    @newsletter = Current.user.newsletters.from_slug(params[:slug])
  end

  def new
    @newsletter = Current.user.newsletters.new
    @new_signup = Current.user.newsletters.count.zero?

    render :new, layout: "application"
  end

  def create
    @newsletter = Current.user.newsletters.new(newsletter_params)
    if @newsletter.save
      redirect_to posts_url(@newsletter.slug)
    else
      render :new, status: :unprocessable_entity, layout: "application", notice: @newsletter.errors.full_messages.to_sentence
    end
  end

  private

  def newsletter_params
    params.require(:newsletter).permit(:title, :description, :slug, :timezone)
  end
end
