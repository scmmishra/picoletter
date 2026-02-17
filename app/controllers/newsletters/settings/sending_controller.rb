class Newsletters::Settings::SendingController < ApplicationController
  include NewsletterScoped
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action -> { authorize_permission!(:sending, :read) }, only: [ :show ]
  before_action -> { authorize_permission!(:sending, :write) }, only: [ :update, :verify_domain ]

  def show; end

  def update
    DomainSetupService.new(@newsletter, sending_params).perform
    redirect_to settings_sending_path(slug: @newsletter.slug), notice: "Settings successfully updated."
  rescue StandardError => e
    Rails.error.report(e, context: { params: sending_params, newsletter_id: @newsletter.id })
    redirect_to settings_sending_path(slug: @newsletter.slug), alert: e.message
  end

  def verify_domain
    @newsletter.verify_custom_domain
    notice = @newsletter.ses_verified? ? "Domain successfully verified." : "Waiting for domain verification."
    redirect_to settings_sending_path(slug: @newsletter.slug), notice: notice
  end

  private

  def sending_params
    params.require(:newsletter).permit(:reply_to, :sending_address, :sending_name)
  end
end
