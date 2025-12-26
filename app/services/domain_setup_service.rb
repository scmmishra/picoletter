class DomainSetupService
  attr_accessor :newsletter, :reply_to, :sending_address, :domain_to_register, :sending_name

  def initialize(newsletter, sending_params)
    self.newsletter = newsletter
    self.reply_to = sending_params[:reply_to]
    self.sending_address = sending_params[:sending_address]
    self.sending_name = sending_params[:sending_name]
    self.domain_to_register = sending_params[:sending_address].split("@").last
  end

  def perform
    raise "Domain name invalid" if !valid_domain?
    raise "Domain already in use" if domain_already_registered?

    ActiveRecord::Base.transaction do
      remove_current_domain if has_existing_domain?
      ensure_newsletter_tenant
      newsletter.update(sending_address: sending_address, reply_to: reply_to, sending_name: sending_name)
      domain = Domain.find_or_create_by(name: domain_to_register, newsletter_id: newsletter.id)
      domain.register_or_sync(tenant_name: tenant_name)
    end
  end

  private

  # Removes the current sending domain configuration for a newsletter
  # Attempts to delete both the SES identity and local database record
  # Handles cases where the domain doesn't exist in SES but needs cleanup in DB
  #
  # @throws {Aws::SESV2::Errors::NotFoundException} When domain not found in SES
  # @throws {StandardError} On other errors during removal
  # @returns {void}
  def remove_current_domain
    begin
      newsletter.sending_domain.drop_identity
    rescue Aws::SESV2::Errors::NotFoundException => e
      Rails.logger.error("Domain not found in SES: #{e.message}, deleting from DB anyway")
    rescue StandardError => e
      context = {
        newsletter_id: newsletter.id,
        existing_domain: newsletter.sending_domain.name,
        new_domain: domain_to_register
      }
      RorVsWild.record_error(e, context: context)
    end

    newsletter.sending_domain.destroy!
  end

  def valid_domain?
    return false unless domain_to_register.present?
    return false unless domain_to_register.include?(".")
    return false if domain_to_register.include?("@")
    return false if domain_to_register.start_with?(".")
    return false if domain_to_register.end_with?(".")

    true
  end

  def has_existing_domain?
    newsletter.sending_domain.present? and newsletter.sending_domain.name != domain_to_register
  end

  def domain_already_registered?
    !Domain.is_unique(domain_to_register, newsletter.id)
  end

  def ensure_newsletter_tenant
    return unless AppConfig.ses_tenants_enabled?
    return if newsletter.ses_tenant_id.present?

    tenant_name = newsletter.generate_tenant_name
    config_set = AppConfig.get("AWS_SES_CONFIGURATION_SET")

    SES::TenantService.new.create_tenant(tenant_name, config_set)
    newsletter.update_column(:ses_tenant_id, tenant_name)
  rescue => e
    Rails.logger.error("Failed to create tenant in DomainSetupService: #{e.message}")
    # Non-blocking: continue with domain setup
  end

  def tenant_name
    AppConfig.ses_tenants_enabled? ? newsletter.ses_tenant_id : nil
  end
end
