namespace :subscribers do
  desc "Verify subscriber emails for a newsletter and unsubscribe invalid ones"
  task verify_emails: :environment do
    newsletter_id = ENV["NEWSLETTER_ID"] || ARGV[1]

    if newsletter_id.blank?
      puts "Please provide a newsletter ID"
      puts "Usage: rake subscribers:verify_emails NEWSLETTER_ID=1"
      puts "   or: rake 'subscribers:verify_emails[1]'"
      exit 1
    end

    # Remove the argument from ARGV to avoid rake complaining about wrong number of arguments
    ARGV.each { |a| task a.to_sym do ; end }

    newsletter = Newsletter.find_by(id: newsletter_id)
    unless newsletter
      puts "Newsletter with ID #{newsletter_id} not found"
      exit 1
    end

    invalid_count = 0
    total_count = newsletter.subscribers.count

    puts "Starting email verification for #{total_count} subscribers in newsletter '#{newsletter.title}'"

    newsletter.subscribers.find_each do |subscriber|
      ves = VerifyEmailService.new(subscriber.email)
      unless ves.valid?
        puts "Invalid email found: #{subscriber.email}"
        subscriber.unsubscribe_with_reason!(:spam)
        invalid_count += 1
      end
    end

    puts "\nVerification complete!"
    puts "Total subscribers processed: #{total_count}"
    puts "Invalid emails found and unsubscribed: #{invalid_count}"
  end
end
