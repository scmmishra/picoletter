class Newsletters::LabelsController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter

  def index
    @labels = @newsletter.labels
  end

  def update
    @label = @newsletter.labels.find(params[:id])
    if @label.update(label_params)
      redirect_to labels_path(slug: @newsletter.slug), notice: "Label updated successfully."
    else
      render :index
    end
  end

  def create
    @label = @newsletter.labels.new(label_params)
    if @label.save
      redirect_to labels_path(slug: @newsletter.slug), notice: "Label created successfully."
    else
      render :new
    end
  end

  def destroy
    @label = @newsletter.labels.find(params[:id])
    @label.destroy
    redirect_to labels_path(slug: @newsletter.slug), notice: "Label deleted successfully."
  end

  private

  def label_params
    params.require(:label).permit(:name, :color, :description)
  end

  def set_newsletter
    @newsletter = Newsletter.find_by(slug: params[:slug])
  end
end
