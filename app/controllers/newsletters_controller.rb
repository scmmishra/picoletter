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
  end
end
