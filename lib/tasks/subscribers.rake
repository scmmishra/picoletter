require "csv"
require "pathname"

namespace :subscribers do
  desc "Verify subscriber emails for a newsletter and unsubscribe invalid ones"
  task clean: :environment do
    newsletter_id = ENV["NEWSLETTER_ID"]
    dry_run = ENV["DRY_RUN"].present?

    if newsletter_id.blank?
      puts "Please provide a newsletter ID"
      puts "Usage: rake subscribers:clean NEWSLETTER_ID=1 [DRY_RUN=1]"
      exit 1
    end

    newsletter = Newsletter.find_by(id: newsletter_id)
    unless newsletter
      puts "Newsletter with ID #{newsletter_id} not found"
      exit 1
    end

    invalid_count = 0
    total_count = newsletter.subscribers.subscribed.count

    puts "Starting email verification for #{total_count} subscribers in newsletter '#{newsletter.title}'"
    puts "DRY RUN MODE - No subscribers will be unsubscribed" if dry_run

    newsletter.subscribers.subscribed.find_each do |subscriber|
      ves = VerifyEmailService.new(subscriber.email)
      unless ves.valid?
        if dry_run
          puts "[DRY RUN] Would unsubscribe invalid email: #{subscriber.email}"
        else
          puts "Invalid email found: #{subscriber.email}"
          subscriber.unsubscribe_with_reason!("spam")
        end
        invalid_count += 1
      end
    end

    puts "\nVerification complete!"
    puts "Total subscribers processed: #{total_count}"
    if dry_run
      puts "Invalid emails that would be unsubscribed: #{invalid_count}"
    else
      puts "Invalid emails found and unsubscribed: #{invalid_count}"
    end
  end

  desc "Import subscribers for a newsletter from a CSV file"
  task import: :environment do
    newsletter_id = ENV["NEWSLETTER_ID"]
    csv_file = ENV["FILE"]
    dry_run = ENV["DRY_RUN"].present?

    if newsletter_id.blank? || csv_file.blank?
      puts "Usage: rake subscribers:import NEWSLETTER_ID=1 FILE=path/to/subscribers.csv [DRY_RUN=1]"
      exit 1
    end

    newsletter = Newsletter.find_by(id: newsletter_id)

    unless newsletter
      puts "Newsletter with ID #{newsletter_id} not found"
      exit 1
    end

    csv_path = Pathname.new(csv_file)
    csv_path = csv_path.absolute? ? csv_path : Rails.root.join(csv_path)

    unless csv_path.exist?
      puts "CSV file not found at #{csv_path}"
      exit 1
    end

    rows = CSV.read(csv_path, headers: true)

    if rows.empty?
      puts "No rows found in CSV file at #{csv_path}"
      exit 0
    end

    total_rows = rows.size
    counters = {
      processed: 0,
      created: 0,
      updated: 0,
      invalid_email: 0,
      failed: 0,
      skipped_unsubscribed: 0
    }

    puts "Importing subscribers for '#{newsletter.title}'"
    puts "Source file: #{csv_path}"
    puts "Dry run: no changes will be saved" if dry_run

    update_progress = lambda do |processed|
      percent = total_rows.positive? ? ((processed.to_f / total_rows) * 100).round(1) : 100.0
      bar_width = 30
      filled = ((percent / 100.0) * bar_width).round
      bar = "#" * filled + "-" * (bar_width - filled)
      summary = "created: #{counters[:created]}, updated: #{counters[:updated]}, invalid: #{counters[:invalid_email]}, failed: #{counters[:failed]}, skipped: #{counters[:skipped_unsubscribed]}"
      print "\r[#{bar}] #{percent.to_s.rjust(5)}% (#{processed}/#{total_rows}) #{summary}"
      $stdout.flush
    end

    rows.each do |row|
      counters[:processed] += 1

      email = row["email"].to_s.strip

      if email.blank?
        counters[:failed] += 1
        update_progress.call(counters[:processed])
        next
      end

      email_verifier = VerifyEmailService.new(email)

      unless email_verifier.verify
        counters[:invalid_email] += 1
        update_progress.call(counters[:processed])
        next
      end

      subscriber = newsletter.subscribers.find_or_initialize_by(email: email)
      was_new = subscriber.new_record?

      if subscriber.unsubscribed? && !was_new
        counters[:skipped_unsubscribed] += 1
        update_progress.call(counters[:processed])
        next
      end

      subscriber.full_name = row["full_name"].presence if row.headers.include?("full_name")
      subscriber.notes = row["notes"].presence if row.headers.include?("notes")

      if row.headers.include?("labels")
        parsed_labels = row["labels"].to_s.split(/[;,]/).map { |label| label.strip.downcase }.reject(&:blank?)
        subscriber.labels = parsed_labels
      end

      subscriber.created_via = row["created_via"].presence || "csv_import"
      subscriber.status = :verified
      subscriber.verified_at ||= Time.current
      subscriber.unsubscribed_at = nil
      subscriber.unsubscribe_reason = nil

      begin
        if dry_run
          counters[was_new ? :created : :updated] += 1
        else
          if subscriber.save
            counters[was_new ? :created : :updated] += 1
          else
            counters[:failed] += 1
          end
        end
      rescue StandardError => e
        counters[:failed] += 1
        Rails.logger.error("[subscribers:import] Failed to import #{email}: #{e.message}")
      end

      update_progress.call(counters[:processed])
    end

    print "\r"
    puts "Import complete. Processed #{counters[:processed]} rows."
    puts "  Created: #{counters[:created]}"
    puts "  Updated: #{counters[:updated]}"
    puts "  Invalid email skipped: #{counters[:invalid_email]}"
    puts "  Failed: #{counters[:failed]}"
    puts "  Previously unsubscribed skipped: #{counters[:skipped_unsubscribed]}"
  end
end
