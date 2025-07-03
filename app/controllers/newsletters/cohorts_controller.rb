class Newsletters::CohortsController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action :set_cohort, only: [ :show, :edit, :update, :destroy ]

  def index
    @cohorts = @newsletter.cohorts.order(:name)
  end

  def show
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

  private

  def set_newsletter
    @newsletter = Current.user.newsletters.find_by!(slug: params[:slug])
  end

  def set_cohort
    @cohort = @newsletter.cohorts.find(params[:id])
  end

  def cohort_params
    params.require(:cohort).permit(:name, :description, :emoji, label_ids: [])
  end
end
