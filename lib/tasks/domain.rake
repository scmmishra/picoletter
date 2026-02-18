namespace :domain do
  desc "Force-verify a domain by name (development only). Usage: rake domain:verify[example.com]"
  task :verify, [ :name ] => :environment do |_t, args|
    unless Rails.env.development?
      puts "This task can only be run in development"
      exit 1
    end

    domain_name = args[:name]

    if domain_name.blank?
      puts "Usage: rake domain:verify[example.com]"
      exit 1
    end

    domain = Domain.find_by(name: domain_name)

    unless domain
      puts "Domain '#{domain_name}' not found"
      exit 1
    end

    domain.update!(status: :success, dkim_status: :success, spf_status: :success)
    puts "Domain '#{domain_name}' verified (newsletter: #{domain.newsletter.title})"
  end
end
