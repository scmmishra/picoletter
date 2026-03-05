class SES::TenantPreflightFailed < StandardError; end

class SES::TenantPreflightService
  attr_reader :newsletter

  def initialize(newsletter)
    @newsletter = newsletter
  end

  def ensure_ready!
    ses_tenant = newsletter.ses_tenant || build_missing_tenant!

    if ses_tenant.usable_for_send?
      ses_tenant.update!(last_checked_at: Time.current)
      return ses_tenant.name
    end

    fail_preflight!(ses_tenant, failure_message_for(ses_tenant))
  rescue SES::TenantPreflightFailed
    raise
  rescue StandardError => error
    Rails.error.report(
      error,
      context: { newsletter_id: newsletter.id, ses_tenant_id: newsletter.ses_tenant&.id }
    )
    raise SES::TenantPreflightFailed, "SES tenant preflight failed for newsletter #{newsletter.id}"
  end

  private

  def build_missing_tenant!
    newsletter.create_ses_tenant!(
      name: SES::TenantService.default_tenant_name(newsletter),
      status: :failed,
      last_error: "SES tenant record is missing.",
      last_checked_at: Time.current
    )
  rescue ActiveRecord::RecordNotUnique
    newsletter.reload.ses_tenant
  end

  def fail_preflight!(ses_tenant, message)
    ses_tenant.update!(
      status: :failed,
      last_error: message,
      last_checked_at: Time.current
    )

    error = SES::TenantPreflightFailed.new(message)
    Rails.error.report(
      error,
      context: {
        newsletter_id: newsletter.id,
        ses_tenant_id: ses_tenant.id,
        ses_tenant_status: ses_tenant.status
      }
    )
    raise error
  end

  def failure_message_for(ses_tenant)
    if ses_tenant.name.blank?
      "SES tenant has no name configured."
    else
      "SES tenant is not ready (status=#{ses_tenant.status})."
    end
  end
end
