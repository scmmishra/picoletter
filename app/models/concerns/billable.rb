module Billable
  extend ActiveSupport::Concern

  def total_subscribers_count
    self.subscribers.verified.count
  end

  def emails_sent_this_month
    start_date = Time.current.beginning_of_month
    end_date = Time.current.end_of_month
    self.emails.where(status: :sent, created_at: start_date..end_date).count
  end

  def init_customer
    HTTParty.post("#{billing_endpoint}/init",
      headers: headers,
      body: {
        id: self.id,
        name: self.name,
        email: self.email
      }.to_json
    )
  end

  def billing_manage_url
    response = HTTParty.get("#{billing_endpoint}/manage/#{self.id}",
      headers: headers
    )

    response.parsed_response["customerPortalUrl"]
  end

  def billing_checkout_url
    response = HTTParty.get("#{billing_endpoint}/checkout/#{self.id}",
      headers: headers
    )

    response.parsed_response["url"]
  end

  def update_meter(count)
    HTTParty.post("#{billing_endpoint}/injest",
      headers: headers,
      body: {
        id: self.id,
        count: count
      }.to_json
    )
  end

  def subscribed?
    return true unless AppConfig.billing_enabled?

    subscription[:status] === "active"
  end

  def subscription
    return {} if self.additional_data.nil?
    self.additional_data["subscription"]&.with_indifferent_access || {}
  end

  private

  def billing_endpoint
    if Rails.env.development?
      "http://localhost:8787"
    else
      "https://billing.picoletter.com"
    end
  end

  def headers
    {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{ENV['ADMIN_API_KEY']}"
    }
  end
end
