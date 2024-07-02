class Public::NewslettersController < ApplicationController
  before_action :set_newsletter

  def show
  end

  private

  def set_newsletter
    @newsletter = Newsletter.from_slug(params[:slug])
  end
end
