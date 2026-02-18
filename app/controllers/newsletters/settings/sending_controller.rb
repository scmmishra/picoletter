class Newsletters::Settings::SendingController < ApplicationController
  include NewsletterScoped
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action -> { authorize_permission!(:sending, :read) }, only: [ :show ]
  before_action -> { authorize_permission!(:sending, :write) }, only: [ :update, :connect_domain, :verify_domain, :disconnect_domain ]

  def show; end

  def connect_domain
    @newsletter.connect_sending_domain(params[:domain])
    redirect_to settings_sending_path(slug: @newsletter.slug), notice: "Domain connected. Please add the DNS records below to verify it."
  rescue StandardError => e
    Rails.error.report(e, context: { domain: params[:domain], newsletter_id: @newsletter.id })
    redirect_to settings_sending_path(slug: @newsletter.slug), alert: e.message
  end

  def update
    validate_sending_address!

    @newsletter.update!(
      sending_name: params[:newsletter][:sending_name],
      sending_address: params[:newsletter][:sending_address],
      reply_to: params[:newsletter][:reply_to]
    )
    redirect_to settings_sending_path(slug: @newsletter.slug), notice: "Settings successfully updated."
  rescue StandardError => e
    Rails.error.report(e, context: { params: params, newsletter_id: @newsletter.id })
    redirect_to settings_sending_path(slug: @newsletter.slug), alert: e.message
  end

  def verify_domain
    @newsletter.verify_custom_domain
    notice = @newsletter.ses_verified? ? "Domain successfully verified." : "Waiting for domain verification."
    redirect_to settings_sending_path(slug: @newsletter.slug), notice: notice
  end

  private

  def validate_sending_address!
    address = params[:newsletter][:sending_address].to_s
    domain = @newsletter.sending_domain

    raise "No sending domain connected." unless domain.present?

    local, domain_part = address.split("@", 2)
    raise "Sending address must be a valid email." if local.blank? || domain_part.blank?
    raise "Sending address must use your connected domain #{domain.name}." unless domain_part == domain.name
  end

  def disconnect_domain
    @newsletter.disconnect_sending_domain
    redirect_to settings_sending_path(slug: @newsletter.slug), notice: "Sending domain disconnected successfully."
  rescue StandardError => e
    Rails.error.report(e, context: { newsletter_id: @newsletter.id })
    redirect_to settings_sending_path(slug: @newsletter.slug), alert: "Failed to disconnect domain."
  end
end
