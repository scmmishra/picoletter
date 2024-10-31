class SES::EmailService < BaseAwsService
  # Send an email using Amazon SES
  #
  # @param [Hash] params Email parameters
  # @option params [Array<String>] :to Recipient email addresses
  # @option params [String] :from Sender email address
  # @option params [String] :reply_to Reply-to email address
  # @option params [String] :subject Email subject line
  # @option params [String] :html HTML email content
  # @option params [String] :text Plain text email content
  # @option params [Hash<String, String>] :headers Additional email headers
  #
  # @return [AWS::SES::Types::SendEmailResponse] Response from SES API
  #
  # @example Basic usage
  #   email_service.send(
  #     to: ['user@example.com'],
  #     from: 'sender@example.com',
  #     reply_to: 'reply@example.com',
  #     subject: 'Hello',
  #     html: '<p>HTML content</p>',
  #     text: 'Text content',
  #     headers: {'List-Unsubscribe' => '<url>'}
  #   )
  def send(params)
    payload = build_email_payload(params)

    @ses_client.send_email(payload)
  end

  private

  def build_email_payload(params)
    parsed_headers = params.fetch(:headers, {}).map { |key, value| { name: key, value: value } }

    {
      from_email_address: params[:from],
      destination: { to_addresses: params[:to] },
      reply_to_addresses: [ params[:reply_to] ],
      content: {
        simple: {
          subject: { data: params[:subject] },
          body: {
            text: { data: params[:text] },
            html: { data: params[:html] }
          },
          headers: parsed_headers
        }
      },
      configuration_set_name: configuration_set
    }
  end

  def configuration_set
    @configuration_set ||= AppConfig.get("AWS_SES_CONFIGURATION_SET")
  end
end
