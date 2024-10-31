class SES::EmailService < BaseAwsService
  # {
  #   to: [emails],
  #   from: someemail@example.com,
  #   reply_to: reply@example.com,
  #   subject: "Some subject",
  #   html: "HTML content",
  #   text: "Text content",
  #   headers: {
  #     'List-Unsubscribe': "<url>",
  #   }
  # }
  def send(params)
    parsed_headers = params[:headers].map do |key, value|
      { name: key, value: value }
    end

    @ses_client.send_email(
      from_email_address: params[:from],
      destination: {
        to_addresses: params[:to]
      },
      reply_to_addresses: params[:reply_to],
      content: {
        simple: {
          subject: {
            data: params[:subject]
          },
          body: {
            text: {
              data: params[:text]
            },
            html: {
              data: params[:html]
            }
          },
          headers: parsed_headers
        }
      }
    )
  end
end
