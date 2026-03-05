class SyncSESTenantJob < ApplicationJob
  queue_as :default

  def perform(newsletter_id)
    newsletter = Newsletter.find(newsletter_id)
    SES::TenantService.new(newsletter: newsletter).sync_resources!
  rescue ActiveRecord::RecordNotFound
    nil
  rescue StandardError => error
    Rails.error.report(error, context: { newsletter_id: newsletter_id })
    raise
  end
end
