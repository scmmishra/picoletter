class NewslettersController < ApplicationController
  before_action :ensure_authenticated

  def index
    @newsletters = Current.user.newsletters.all
  end

  def show
    @newsletter = Current.user.newsletters.find(params[:id])
  end

  def new
  end
end
