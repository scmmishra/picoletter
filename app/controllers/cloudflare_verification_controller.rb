class CloudflareVerificationController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    publishing_domain = find_publishing_domain

    if verification_payload_present?(publishing_domain)
      render plain: publishing_domain.verification_http_body, content_type: "text/plain"
    else
      head :not_found
    end
  end

  private

  def find_publishing_domain
    host = request.host&.downcase
    return if host.blank?

    PublishingDomain.find_by(hostname: host)
  end

  def verification_payload_present?(publishing_domain)
    return false if publishing_domain.nil?

    stored_path = publishing_domain.verification_http_path
    stored_body = publishing_domain.verification_http_body

    stored_path.present? &&
      stored_body.present? &&
      stored_path.casecmp?(request.path)
  end
end
