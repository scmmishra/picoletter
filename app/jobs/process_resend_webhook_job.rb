class ProcessResendWebhookJob < ApplicationJob
  queue_as :default

  def perform(payload)
    @payload = payload.with_indifferent_access
    @email = find_email_log

    event_name = @payload[:type].to_s.gsub(".", "_")

    if self.respond_to?("process_#{event_name}")
      send("process_#{event_name}")
    end
  end

  def process_email_delivered
    @email.update(status: "delivered", delivered_at: @payload.dig(:data, :created_at))
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

  private

  def find_email_log
    Email.find_by(email_id: @payload.dig(:data, :email_id))
  end
end
