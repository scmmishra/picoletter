# Ad-hoc Email Sending Task
#
# This task sends personalized emails to recipients listed in a CSV file using a custom template.
# It validates the template before sending and supports dry-run mode for testing.
#
# Usage:
#   rake email:send_adhoc[newsletter_id,template_name,subject] DRY_RUN=true
#
# Examples:
#   # Dry run to test template and data
#   rake email:send_adhoc[1,fair_usage,"Fair Usage Update"] DRY_RUN=true
#
#   # Send emails live
#   rake email:send_adhoc[1,fair_usage,"Fair Usage Update"]
#
# Requirements:
#   - Template file: template_name.liquid (in project root, using Liquid syntax)
#   - CSV file: template_name.csv (in project root)
#   - CSV columns: email, plan_name, account_name (or other data fields)
#
# Template variables available (Liquid syntax):
#   - {{ data.email }}, {{ data.plan_name }}, {{ data.account_name }} (from CSV)
#   - {{ newsletter.title }}, {{ newsletter.sending_name }} (from newsletter)
#
# Features:
#   - Pre-validates template rendering for all CSV rows
#   - Individual email sending (no batching)
#   - No unsubscribe links included
#   - Uses newsletter's sender configuration
#   - Detailed error reporting
#
namespace :email do
  desc "Send ad-hoc emails from CSV data"
  task :send_adhoc, [ :newsletter_id, :template_name, :subject ] => :environment do |task, args|
    # Parse options
    newsletter_id = args[:newsletter_id]
    template_name = args[:template_name]
    subject = args[:subject]

    # Check for dry run option
    dry_run = ENV["DRY_RUN"] == "true"

    # Validate required arguments
    unless newsletter_id && template_name && subject
      puts "Usage: rake email:send_adhoc[newsletter_id,template_name,subject] DRY_RUN=true"
      puts "Example: rake email:send_adhoc[1,fair_usage,'Fair Usage Policy Update'] DRY_RUN=true"
      exit 1
    end

    # Construct file paths
    template_path = Rails.root.join("#{template_name}.liquid")
    csv_path = Rails.root.join("#{template_name}.csv")

    # Check if files exist
    unless File.exist?(template_path)
      puts "Error: Template file not found at #{template_path}"
      exit 1
    end

    unless File.exist?(csv_path)
      puts "Error: CSV file not found at #{csv_path}"
      exit 1
    end

    # Validate newsletter exists
    begin
      newsletter = Newsletter.find(newsletter_id)
    rescue ActiveRecord::RecordNotFound
      puts "Error: Newsletter with ID #{newsletter_id} not found"
      exit 1
    end

    puts "Newsletter: #{newsletter.title}"
    puts "Template: #{template_name}"
    puts "Subject: #{subject}"
    puts "CSV File: #{csv_path}"
    puts "Mode: #{dry_run ? 'DRY RUN' : 'LIVE'}"
    puts "=" * 50

    # Initialize service
    service = SendAdhocEmailService.new(newsletter_id, template_name, subject, csv_path)

    # Validate template rendering first
    puts "Validating template rendering..."
    if service.validate_template
      puts "✓ Template validation passed"
    else
      puts "✗ Template validation failed with errors:"
      service.instance_variable_get(:@errors).each do |error|
        puts "  Row #{error[:row]}: #{error[:error]}"
        puts "    Data: #{error[:data]}"
      end
      exit 1
    end

    # Send emails
    puts "\nSending emails..."
    result = service.send_emails(dry_run: dry_run)

    puts "\nResults:"
    puts "Sent: #{result[:sent]} emails"

    if result[:errors].any?
      puts "Errors: #{result[:errors].count}"
      result[:errors].each do |error|
        puts "  #{error[:email]}: #{error[:error]}"
      end
    else
      puts "✓ All emails processed successfully"
    end
  end
end
