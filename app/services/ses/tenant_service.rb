class SES::TenantService < BaseAwsService
  def create_tenant(tenant_name, config_set_name = nil)
    @ses_client.create_tenant(tenant_name: tenant_name)

    if config_set_name.present?
      associate_configuration_set(tenant_name, config_set_name)
    end
  end

  def delete_tenant(tenant_name)
    @ses_client.delete_tenant(tenant_name: tenant_name)
  end

  def identity_arn(domain)
    "arn:aws:ses:#{@region}:#{account_id}:identity/#{domain}"
  end

  def configuration_set_arn(config_set_name)
    "arn:aws:ses:#{@region}:#{account_id}:configuration-set/#{config_set_name}"
  end

  def associate_identity(tenant_name, domain)
    @ses_client.create_tenant_resource_association(
      tenant_name: tenant_name,
      resource_arn: identity_arn(domain)
    )
  end

  def disassociate_identity(tenant_name, domain)
    @ses_client.delete_tenant_resource_association(
      tenant_name: tenant_name,
      resource_arn: identity_arn(domain)
    )
  rescue Aws::SESV2::Errors::NotFoundException
    # Gracefully handle missing associations
  end

  def associate_configuration_set(tenant_name, config_set_name)
    @ses_client.create_tenant_resource_association(
      tenant_name: tenant_name,
      resource_arn: configuration_set_arn(config_set_name)
    )
  end

  def disassociate_configuration_set(tenant_name, config_set_name)
    @ses_client.delete_tenant_resource_association(
      tenant_name: tenant_name,
      resource_arn: configuration_set_arn(config_set_name)
    )
  rescue Aws::SESV2::Errors::NotFoundException
    # Gracefully handle missing associations
  end

  private

  def account_id
    @account_id ||= begin
      sts_client = Aws::STS::Client.new(region: @region)
      sts_client.get_caller_identity.account
    end
  end
end
