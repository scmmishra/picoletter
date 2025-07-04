class Newsletters::CohortsController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action :set_cohort, only: [ :show, :edit, :update, :destroy ]

  def index
    @cohorts = @newsletter.cohorts.order(:name)
  end

  def show
    @pagy, @cohort_subscribers = pagy(@cohort.subscribers, limit: 15)
  end

  def new
    @cohort = @newsletter.cohorts.build
    @labels = @newsletter.labels.order(:name)
  end

  def create
    @cohort = @newsletter.cohorts.build(cohort_params)
    @labels = @newsletter.labels.order(:name)

    if @cohort.save
      redirect_to cohort_path(@newsletter.slug, @cohort), notice: "Cohort was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @labels = @newsletter.labels.order(:name)
  end

  def update
    @labels = @newsletter.labels.order(:name)

    if @cohort.update(cohort_params)
      redirect_to cohort_path(@newsletter.slug, @cohort), notice: "Cohort was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @cohort.destroy
    redirect_to cohorts_path(@newsletter.slug), notice: "Cohort was successfully deleted."
  end

  def add_condition
    @index = params[:index]&.to_i || 0

    respond_to do |format|
      format.turbo_stream
    end
  end


  private

  def set_newsletter
    @newsletter = Current.user.newsletters.find_by!(slug: params[:slug])
  end

  def set_cohort
    @cohort = @newsletter.cohorts.find(params[:id])
  end

  def cohort_params
    permitted = params.require(:cohort).permit(:name, :description, :icon, :color, :filter_conditions)

    # Parse JSON filter_conditions if present
    if permitted[:filter_conditions].present?
      begin
        permitted[:filter_conditions] = JSON.parse(permitted[:filter_conditions])
      rescue JSON::ParserError
        # If parsing fails, set to empty hash
        permitted[:filter_conditions] = {}
      end
    end

    permitted
  end
end
