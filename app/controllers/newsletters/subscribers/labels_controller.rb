class Newsletters::Subscribers::LabelsController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action :set_subscriber

  def add
    @label = @newsletter.labels.find_by(name: params[:label_name])

    if @label && !@subscriber.labels.include?(@label.name)
      @subscriber.labels = (@subscriber.labels + [ @label.name ]).uniq
      @subscriber.save
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  def remove
    @label = @newsletter.labels.find_by(name: params[:label_name])

    if @label && @subscriber.labels.include?(@label.name)
      @subscriber.labels = @subscriber.labels - [ @label.name ]
      @subscriber.save
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_newsletter
    @newsletter = Newsletter.find_by(slug: params[:slug])
  end

  def set_subscriber
    @subscriber = @newsletter.subscribers.find(params[:id])
  end
end
