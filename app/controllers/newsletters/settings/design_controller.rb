class Newsletters::Settings::DesignController < ApplicationController
  include NewsletterScoped
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action -> { authorize_permission!(:design, :read) }, only: [ :show ]
  before_action -> { authorize_permission!(:design, :write) }, only: [ :update ]

  def show; end

  def update
    @newsletter.update(design_params)
    redirect_to settings_design_path(slug: @newsletter.slug), notice: "Design successfully updated."
  end

  private

  def design_params
    params.require(:newsletter).permit(:email_css, :email_footer, :font_preference, :primary_color, :template)
  end
end
