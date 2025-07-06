class Newsletters::CohortsController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action :set_cohort, only: [ :show, :edit, :update, :destroy ]

  def show
    @pagy, @cohort_subscribers = pagy(@cohort.subscribers, limit: 15)
    # Store where the user came from so we can redirect back there after deletion
    session[:cohort_return_to] = request.referer if request.referer.present?
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
    # Redirect back to where the user came from before viewing this cohort
    # If no stored location, fall back to newsletter home page
    return_to = session.delete(:cohort_return_to) || posts_path(@newsletter.slug)
    redirect_to return_to, notice: "Cohort was successfully deleted."
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
