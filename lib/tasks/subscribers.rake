namespace :subscribers do
  desc "Verify subscriber emails for a newsletter and unsubscribe invalid ones"
  task verify_emails: :environment do
    newsletter_id = ENV["NEWSLETTER_ID"]
    dry_run = ENV["DRY_RUN"].present?

    if newsletter_id.blank?
      puts "Please provide a newsletter ID"
      puts "Usage: rake subscribers:verify_emails NEWSLETTER_ID=1 [DRY_RUN=1]"
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
end
