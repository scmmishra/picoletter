class DomainSetupService
  attr_accessor :newsletter, :reply_to, :sending_address, :domain_to_register

  def initialize(newsletter, sending_params)
    self.newsletter = newsletter
    self.reply_to = sending_params[:reply_to]
    self.sending_address = sending_params[:sending_address]
    self.domain_to_register = sending_params[:sending_address].split("@").last
  end

  def perform
    raise "Domain name invalid" if !valid_domain?
    raise "Domain already in use" if domain_already_registered?

    ActiveRecord::Base.transaction do
      remove_current_domain if has_existing_domain?
      newsletter.update(sending_address: sending_address, reply_to: reply_to)
      domain = Domain.find_or_create_by(name: domain_to_register, newsletter_id: newsletter.id)
      domain.register_or_sync()
    end
  end

  private

  def remove_current_domain
    newsletter.sending_domain.drop_identity
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
    newsletter.sending_domain.present? and newsletter.sending_domain.verified? and newsletter.sending_domain.name != domain_to_register
  end

  def domain_already_registered?
    !Domain.is_unique(domain_to_register, newsletter.id)
  end
end
