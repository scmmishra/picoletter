namespace :ses_tenants do
  desc "Backfill SES tenants for existing newsletters"
  task backfill: :environment do
    unless AppConfig.ses_tenants_enabled?
      puts "SES tenants are not enabled. Set ENABLE_SES_TENANTS=true to proceed."
      exit 1
    end

    config_set = AppConfig.get("AWS_SES_CONFIGURATION_SET")
    unless config_set.present?
      puts "AWS_SES_CONFIGURATION_SET is not configured."
      exit 1
    end

    tenant_service = SES::TenantService.new

    newsletters_without_tenant = Newsletter.where(ses_tenant_id: nil)
    total_count = newsletters_without_tenant.count

    puts "Found #{total_count} newsletters without tenants"
    puts "Starting backfill..."
    puts ""

    success_count = 0
    error_count = 0
    errors = []

    newsletters_without_tenant.find_each.with_index do |newsletter, index|
      print "\rProcessing newsletter #{index + 1}/#{total_count} (ID: #{newsletter.id})..."

      begin
        tenant_name = newsletter.generate_tenant_name

        # Try to create tenant - handle case where it may already exist
        begin
          tenant_service.create_tenant(tenant_name, config_set)
        rescue Aws::SESV2::Errors::AlreadyExistsException
          puts "\n  Tenant already exists, associating config set..."
          # If tenant exists, just ensure config set is associated
          tenant_service.associate_configuration_set(tenant_name, config_set)
        end

        # Associate domain if exists and verified
        if newsletter.sending_domain&.verified?
          domain = newsletter.sending_domain

          begin
            # Associate identity with tenant
            tenant_service.associate_identity(tenant_name, domain.name)
            domain.update_column(:ses_tenant_id, tenant_name)
          rescue Aws::SESV2::Errors::AlreadyExistsException
            # Already associated, continue
          rescue Aws::SESV2::Errors::NotFoundException
            # Identity doesn't exist in SES, skip association
            puts "\n  Warning: Domain #{domain.name} not found in SES, skipping association"
          end
        end

        # Update newsletter with tenant ID
        newsletter.update_column(:ses_tenant_id, tenant_name)

        success_count += 1
      rescue => e
        error_count += 1
        error_message = "Newsletter ID #{newsletter.id}: #{e.class} - #{e.message}"
        errors << error_message
        puts "\n  Error: #{error_message}"
      end
    end

    puts "\n"
    puts "=" * 80
    puts "Backfill complete!"
    puts "  Total processed: #{total_count}"
    puts "  Successful: #{success_count}"
    puts "  Errors: #{error_count}"

    if errors.any?
      puts "\nErrors encountered:"
      errors.each { |error| puts "  - #{error}" }
    end
  end

  desc "Cleanup orphaned tenants (tenants without matching newsletters)"
  task cleanup_orphaned: :environment do
    unless AppConfig.ses_tenants_enabled?
      puts "SES tenants are not enabled. Set ENABLE_SES_TENANTS=true to proceed."
      exit 1
    end

    puts "This task would require listing all SES tenants and comparing with database."
    puts "AWS SES does not provide a ListTenants API, so orphaned tenants must be tracked manually."
    puts ""
    puts "Orphaned tenants can occur when:"
    puts "  1. Newsletter is created and tenant is created, but transaction fails"
    puts "  2. Database is rolled back but AWS tenant creation succeeded"
    puts ""
    puts "To manually clean up an orphaned tenant:"
    puts "  1. Identify the tenant name (format: newsletter-<id>-<random>)"
    puts "  2. Run: rails runner 'SES::TenantService.new.delete_tenant(\"tenant-name\")'"
  end
end
