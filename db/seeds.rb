# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
require "kramdown"
require 'faker'

def extract_frontmatter(content)
  if content.start_with?("---")
    end_index = content.index("---", 3)
    if end_index
      yaml_content = content[3...end_index].strip
      frontmatter = YAML.load(yaml_content)
      return frontmatter
    end
  end

  nil
end


user = User.create!(
  name: "Neo Anderson",
  email: "neo@example.com",
  password: "root",
)

user.save!

puts "Created user #{user.name}"

newsletter = user.newsletters.create!(
  title: "TinyJS",
  description: "Top 3 stories from the JavaScript ecosystem, dispatched weekly.",
)

puts "Created newsletter #{newsletter.title}"

seed_data_path = Rails.root.join("db", "seed_data", "posts")
publish_date = Time.now

Dir.glob(File.join(seed_data_path, "*.md")).each do |file|
  content = File.read(file)
  frontmatter = extract_frontmatter(content)
  title = frontmatter["title"]

  html_content = Kramdown::Document.new(content).to_html
  created_at = publish_date - rand(1..3).days

  newsletter.posts.create!(
    title: title,
    content: html_content,
    published_at: publish_date,
    created_at: created_at,
    updated_at: created_at,
    status: :published,
  )

  puts "  Created post #{title}"

  publish_date -= 1.week
end

# loop 100 times and create subscribers
100.times do
  email = Faker::Internet.email
  full_name = Faker::Name.name
  status = [ :verified, :unverified, :unsubscribed ].sample

  # get a random date in the last 3 months
  created_at = Time.now - rand(1..3).months
  subscriber = newsletter.subscribers.create!(
    email: email,
    full_name: full_name,
    status: status,
    created_at: created_at,
    updated_at: created_at,
  )

  if status == :verified || status == :unsubscribed
    subscriber.verified_at = created_at + rand(1..30).hours
  end
  subscriber.save!
end
