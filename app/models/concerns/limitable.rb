module Limitable
  extend ActiveSupport::Concern

  def total_subscribers_count
    self.subscribers.verified.count
  end

  def emails_sent_this_month
    start_date = Time.current.beginning_of_month
    end_date = Time.current.end_of_month
    self.emails.where(status: :sent, created_at: start_date..end_date).count
  end
end
