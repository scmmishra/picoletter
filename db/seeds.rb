puts "Seeding database"

return if Rails.env.production?

unless User.exists?(email: "neo@example.com")
  puts "-- Creating admin user"
  User.create!(
    name: "Neo",
    email: "neo@example.com",
    password: "admin@123456",
    active: true
  )
end

def parse_md_file(content)
  if content.start_with?("---")
    end_index = content.index("---", 3)
    frontmatter = YAML.safe_load(content[3...end_index])
    content = content[(end_index + 3)..]
    return frontmatter, content
  end

  return {}, content
end

puts "-- Creating newsletter"
user = User.find_by!(email: "neo@example.com")
newsletter = user.newsletters.create!(
  title: "The Daily Byte",
  description: "Daily tech insights and programming tips."
)

puts "-- Creating posts"
publish_date = Time.now

Dir.glob("#{Rails.root}/db/posts/*.md").each do |file|
  content = File.read(file)
  frontmatter, content = parse_md_file(content)

  newsletter.posts.create!(
    title: frontmatter["title"],
    content: content,
    status: :published,
    published_at: publish_date
  )

  puts "   Created post: #{frontmatter["title"]}"
  publish_date -= 1.week
end

puts "-- Creating labels"
labels_data = [
  { name: "early-access", color: "#10B981", description: "Early access subscribers" },
  { name: "beta-tester", color: "#3B82F6", description: "Beta program participants" },
  { name: "premium", color: "#8B5CF6", description: "Premium tier subscribers" },
  { name: "inactive", color: "#EF4444", description: "Inactive subscribers" },
  { name: "engaged", color: "#F59E0B", description: "Highly engaged subscribers" }
]

labels = newsletter.labels.create!(labels_data)
puts "   Created #{labels.count} labels"

puts "-- Creating subscribers"
subscribers = []

# Add our test subscriber
subscribers << {
  email: "shivam@shivam.dev",
  full_name: "Shivam Mishra",
  status: :verified,
  created_at: 2.days.ago,
  updated_at: 2.days.ago,
  verified_at: 2.days.ago,
  labels: [ "early-access", "premium" ]
}

# Generate 50 random subscribers
50.times do
  status = [ :verified, :verified, :verified, :unverified, :unsubscribed ].sample
  created_at = rand(1..90).days.ago

  subscriber = {
    email: Faker::Internet.unique.email,
    full_name: Faker::Name.name,
    status: status,
    created_at: created_at,
    updated_at: created_at,
    verified_at: status == :verified ? created_at + rand(1..24).hours : nil,
    unsubscribed_at: status == :unsubscribed ? created_at + rand(1..30).days : nil,
    labels: []
  }

  # Randomly assign labels
  if status == :verified
    # 60% chance of having labels for verified subscribers
    if rand < 0.6
      num_labels = rand(1..3)
      subscriber[:labels] = labels_data.map { |l| l[:name] }.sample(num_labels)
    end
  end

  subscribers << subscriber
end

# Create all subscribers
newsletter.subscribers.create!(subscribers)
puts "   Created #{subscribers.count} subscribers"
