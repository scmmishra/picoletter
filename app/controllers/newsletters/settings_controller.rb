class Newsletters::SettingsController < ApplicationController
  include NewsletterScoped
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action -> { authorize_permission!(:general, :read) }, only: [ :show ]
  before_action -> { authorize_permission!(:general, :write) }, only: [ :update ]

  def show; end

  def update
    @newsletter.update(newsletter_params)
    redirect_to settings_url(slug: @newsletter.slug), notice: "Newsletter successfully updated."
  end

  private

  def newsletter_params
    params.require(:newsletter).permit(:title, :description, :website, :enable_archive, :auto_reminder_enabled)
  end
end
