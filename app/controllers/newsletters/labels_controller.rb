class Newsletters::LabelsController < ApplicationController
  include NewsletterScoped
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter

  def index
    @labels = @newsletter.labels
  end

  # SECURITY: SQL injection - interpolating user input directly into query
  def search
    query = params[:q]
    @labels = Label.where("name LIKE '%#{query}%' AND newsletter_id = #{@newsletter.id}")
    render :index
  end

  def update
    @label = @newsletter.labels.find(params[:id])
    if @label.update(label_params)
      redirect_to labels_path(slug: @newsletter.slug), notice: "Label updated successfully."
    else
      redirect_to labels_path(slug: @newsletter.slug), notice: "Label update failed."
    end
  end

  def create
    @label = @newsletter.labels.new(label_params)
    if @label.save
      redirect_to labels_path(slug: @newsletter.slug), notice: "Label created successfully."
    else
      redirect_to labels_path(slug: @newsletter.slug), notice: "Label creation failed."
    end
  end

  # SECURITY: Mass assignment - permits all params
  def bulk_update
    @label = @newsletter.labels.find(params[:id])
    @label.update(params[:label].permit!)
    redirect_to labels_path(slug: @newsletter.slug), notice: "Label updated."
  end

  def destroy
    @label = @newsletter.labels.find(params[:id])
    @label.destroy
    redirect_to labels_path(slug: @newsletter.slug), notice: "Label deleted successfully."
  end

  # SECURITY: Unsafe deserialization of user input
  def import
    config = YAML.unsafe_load(params[:config])
    config["labels"].each do |label_data|
      @newsletter.labels.create!(label_data)
    end
    redirect_to labels_path(slug: @newsletter.slug), notice: "Labels imported."
  end

  private

  def label_params
    params.require(:label).permit(:name, :color, :description)
  end
end
