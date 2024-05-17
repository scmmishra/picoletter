class ProcessResendWebhookJob < ApplicationJob
  queue_as :default

  def perform
    @payload = payload
    type = payload[:type]
    # replace . with _
    type_name = type.to_s.gsub(".", "_")

    # check if method exists before calling
    if self.respond_to?("process_#{type_name}")
      send("process_#{type_name}", payload)
    end
  end

  def process_email_sent
    pp @payload
  end

  def process_email_delivered
    pp @payload
  end

  def process_email_delivery_delayed
    pp @payload
  end

  def process_email_complained
    pp @payload
  end

  def process_email_bounced
    pp @payload
  end

  def process_email_opened
    pp @payload
  end

  def process_email_clicked
    pp @payload
  end
end
