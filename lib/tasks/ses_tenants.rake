namespace :ses do
  namespace :tenants do
    desc "Backfill SES tenant records and enqueue sync jobs"
    task backfill: :environment do
      created = 0
      queued = 0

      Newsletter.find_each do |newsletter|
        ses_tenant = newsletter.ses_tenant || newsletter.build_ses_tenant

        if ses_tenant.new_record?
          ses_tenant.name = SESTenant.generate_name(newsletter.id)
          ses_tenant.status = :pending
          ses_tenant.save!
          created += 1
        end

        SyncSESTenantJob.perform_later(newsletter.id)
        queued += 1
      rescue StandardError => error
        Rails.error.report(error, context: { newsletter_id: newsletter.id })
      end

      puts "Created #{created} SES tenant records. Enqueued #{queued} sync jobs."
    end

    desc "Audit SES tenant associations against expected resources"
    task audit: :environment do
      missing_tenant_records = 0
      failed_records = 0
      missing_associations = 0

      Newsletter.includes(:ses_tenant, :sending_domain).find_each do |newsletter|
        ses_tenant = newsletter.ses_tenant

        if ses_tenant.blank?
          missing_tenant_records += 1
          puts "Newsletter #{newsletter.id}: missing SES tenant record"
          next
        end

        if ses_tenant.failed?
          failed_records += 1
          puts "Newsletter #{newsletter.id}: tenant failed (#{ses_tenant.last_error})"
        end

        begin
          missing = SES::TenantService.new(newsletter: newsletter).missing_resource_associations
          next if missing.empty?

          missing_associations += 1
          puts "Newsletter #{newsletter.id}: missing associations #{missing.join(', ')}"
        rescue StandardError => error
          Rails.error.report(error, context: { newsletter_id: newsletter.id })
        end
      end

      puts "Missing tenant records: #{missing_tenant_records}"
      puts "Failed tenant records: #{failed_records}"
      puts "Missing associations: #{missing_associations}"
    end

    desc "Repair tenant sync for a single newsletter. Usage: rake ses:tenants:repair[newsletter_id]"
    task :repair, [ :newsletter_id ] => :environment do |_task, args|
      newsletter_id = args[:newsletter_id]
      raise ArgumentError, "newsletter_id is required" if newsletter_id.blank?

      newsletter = Newsletter.find(newsletter_id)
      SyncSESTenantJob.perform_later(newsletter.id)
      puts "Enqueued SyncSESTenantJob for newsletter #{newsletter.id}"
    end
  end
end
