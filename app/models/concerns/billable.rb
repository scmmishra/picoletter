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
    # the API expiry is 30 minutes, we keep a margin of 5 minutes to prevent any bad links
    Rails.cache.fetch("billing_manage_url_#{self.id}", expires_in: 25.minutes) do
      response = HTTParty.get("#{billing_endpoint}/manage/#{self.id}",
        headers: headers
      )

      response["customerPortalUrl"]
    end
  end

  def billing_checkout_url
    # the API expiry is 30 minutes, we keep a margin of 5 minutes to prevent any bad links
    Rails.cache.fetch("billing_checkout_url_#{self.id}", expires_in: 25.minutes) do
      response = HTTParty.get("#{billing_endpoint}/checkout/#{self.id}",
        headers: headers
      )

      response["url"]
    end
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
