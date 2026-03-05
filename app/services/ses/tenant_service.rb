class SES::TenantService < BaseAwsService
  attr_reader :newsletter

  def self.default_tenant_name(newsletter)
    SESTenant.generate_name(newsletter.id)
  end

  def initialize(newsletter:)
    super()
    @newsletter = newsletter
  end

  def ensure_tenant!
    ses_tenant = find_or_build_tenant

    tenant_arn = begin
      @ses_client.get_tenant(tenant_name: ses_tenant.name).tenant.tenant_arn
    rescue Aws::SESV2::Errors::NotFoundException
      @ses_client.create_tenant(tenant_name: ses_tenant.name).tenant_arn
    end

    mark_ready!(ses_tenant: ses_tenant, arn: tenant_arn)
  rescue StandardError => error
    mark_failed!(ses_tenant: ses_tenant, error: error) if ses_tenant
    raise
  end

  def sync_resources!
    ses_tenant = ensure_tenant!

    resource_arns_for(newsletter).each do |resource_arn|
      ensure_resource_association!(tenant_name: ses_tenant.name, resource_arn: resource_arn)
    end

    mark_ready!(ses_tenant: ses_tenant, arn: ses_tenant.arn)
  rescue StandardError => error
    mark_failed!(ses_tenant: ses_tenant, error: error) if ses_tenant
    raise
  end

  def disassociate_custom_identity!
    ses_tenant = newsletter.ses_tenant
    custom_domain = newsletter.sending_domain&.name
    return if ses_tenant.blank? || ses_tenant.name.blank? || custom_domain.blank?

    resource_arn = identity_arn(custom_domain)
    return unless resource_associated_with_tenant?(resource_arn: resource_arn, tenant_name: ses_tenant.name)

    @ses_client.delete_tenant_resource_association(
      tenant_name: ses_tenant.name,
      resource_arn: resource_arn
    )
  rescue Aws::SESV2::Errors::NotFoundException
    nil
  rescue StandardError => error
    mark_failed!(ses_tenant: ses_tenant, error: error) if ses_tenant
    raise
  end

  def missing_resource_associations
    ses_tenant = newsletter.ses_tenant
    return resource_arns_for(newsletter) if ses_tenant.blank? || ses_tenant.name.blank?

    resource_arns_for(newsletter).reject do |resource_arn|
      resource_associated_with_tenant?(resource_arn: resource_arn, tenant_name: ses_tenant.name)
    end
  end

  def mark_failed!(ses_tenant:, error:)
    ses_tenant.update!(
      status: :failed,
      last_error: "#{error.class}: #{error.message}",
      last_checked_at: Time.current
    )
    ses_tenant
  end

  def mark_ready!(ses_tenant:, arn:)
    ses_tenant.update!(
      arn: arn,
      status: :ready,
      last_error: nil,
      last_checked_at: Time.current,
      last_synced_at: Time.current,
      ready_at: Time.current
    )
    ses_tenant
  end

  private

  def find_or_build_tenant
    ses_tenant = newsletter.ses_tenant || newsletter.build_ses_tenant
    ses_tenant.name ||= self.class.default_tenant_name(newsletter)
    ses_tenant.status ||= :pending
    ses_tenant.save! if ses_tenant.new_record? || ses_tenant.changed?
    ses_tenant
  end

  def ensure_resource_association!(tenant_name:, resource_arn:)
    return if resource_associated_with_tenant?(resource_arn: resource_arn, tenant_name: tenant_name)

    @ses_client.create_tenant_resource_association(
      tenant_name: tenant_name,
      resource_arn: resource_arn
    )
  end

  def resource_associated_with_tenant?(resource_arn:, tenant_name:)
    next_token = nil

    loop do
      response = @ses_client.list_resource_tenants(
        resource_arn: resource_arn,
        next_token: next_token,
        page_size: 100
      )

      return true if response.resource_tenants.any? { |resource_tenant| resource_tenant.tenant_name == tenant_name }

      next_token = response.next_token
      break if next_token.blank?
    end

    false
  end

  def resource_arns_for(newsletter)
    arns = [
      configuration_set_arn(configuration_set_name),
      identity_arn(default_identity)
    ]

    custom_domain = newsletter.sending_domain&.name
    arns << identity_arn(custom_domain) if custom_domain.present?
    arns.compact.uniq
  end

  def configuration_set_name
    AppConfig.get!("AWS_SES_CONFIGURATION_SET")
  end

  def default_identity
    default_sending_domain = AppConfig.get("PICO_SENDING_DOMAIN", "picoletter.com")
    "mail.#{default_sending_domain}"
  end

  def configuration_set_arn(name)
    "arn:aws:ses:#{region}:#{account_id}:configuration-set/#{name}"
  end

  def identity_arn(identity)
    "arn:aws:ses:#{region}:#{account_id}:identity/#{identity}"
  end

  def account_id
    @account_id ||= AppConfig.get!("AWS_ACCOUNT_ID")
  end
end
