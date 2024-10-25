class SES::DomainService < BaseAwsService
  def initialize(domain)
    super()
    @domain = domain
  end

  def create_identity
    # we generate a new key pair for each domain
    # instead of relying on AWS to generate it
    # That way we have vendor portability
    private_key, public_key = generate_key_pair

    # Email identity creation in Amazon SES enables domain-based authentication
    # through DomainKeys Identified Mail (DKIM). DKIM allows receiving email
    # servers to verify that an email was authorized by the owner of the domain.
    #
    # The process involves:
    # 1. Generating public/private key pair for DKIM signing
    # 2. Registering the domain with SES using the private key
    # 3. Publishing the public key in DNS for verification
    #
    # This enhances email deliverability by proving domain ownership and
    # message authenticity to receiving email servers.
    @ses_client.create_email_identity({
      email_identity: @domain,
      dkim_signing_attributes: {
        domain_signing_selector: "picoletter",
        domain_signing_private_key: private_key
      }
    })

    # The Mail-From domain defines the domain used in the MAIL FROM
    # (envelope sender) during the email transmission. It serves two
    # key purposes:
    #
    # SPF Authentication: Helps authenticate the sender to prevent
    # spoofing. The receiving server checks if the MAIL FROM domain is
    # authorized to send on behalf of the sender's identity.
    #
    # Bounce Handling: Directs bounced messages to the specified
    # MAIL FROM domain, helping manage delivery issues efficiently.
    #
    # In Amazon SES, the custom MAIL FROM domain allows you to control
    # this value, which can improve deliverability and enhance your
    # domain's email reputation.
    @ses_client.put_email_identity_mail_from_attributes({
      email_identity: @domain,
      mail_from_domain: "mail.#{@domain}"
    })

    public_key
  rescue => e
    Rails.logger.error(e)
    RorVsWild.record_error(e, context: { domain: @domain })
  end

  def get_identity
    @ses_client.get_email_identity({
      email_identity: @domain
    })
  rescue => e
    Rails.logger.error(e)
    RorVsWild.record_error(e, context: { domain: @domain })
    nil
  end

  def delete_identity
    @ses_client.delete_email_identity({
      email_identity: @domain
    })
  rescue => e
    Rails.logger.error(e)
    RorVsWild.record_error(e, context: { domain: @domain })
  end

  private

  def generate_key_pair
    key = OpenSSL::PKey::RSA.new(2048)

    private_key = key.to_pem
    public_key = key.public_key.to_pem

    base64_private_key = private_key
      .gsub("-----BEGIN RSA PRIVATE KEY-----", "")
      .gsub("-----END RSA PRIVATE KEY-----", "")
      .gsub("\n", "")

    base64_public_key = public_key
      .gsub("-----BEGIN PUBLIC KEY-----", "")
      .gsub("-----END PUBLIC KEY-----", "")
      .gsub("\n", "")

    [ base64_private_key, base64_public_key ]
  end
end
