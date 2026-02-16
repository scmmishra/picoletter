puts "Seeding database"

return if Rails.env.production?

# Create users
puts "-- Creating users"
users = [
  {
    name: "Neo Anderson",
    email: "neo@example.com",
    password: "admin@123456",
    active: true
  },
  {
    name: "Morpheus",
    email: "morpheus@example.com",
    password: "admin@123456",
    active: true
  }
]

users.each do |user_data|
  unless User.exists?(email: user_data[:email])
    User.create!(user_data)
    puts "   Created user: #{user_data[:name]}"
  end
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

# Create newsletters for each user
puts "\n-- Creating newsletters"
User.find_each do |user|
  # Tech Newsletter
  tech_newsletter = Newsletter.create!(
    user: user,
    title: "#{user.name}'s Tech Insider",
    description: "Deep dives into technology, programming, and software architecture."
  )
  puts "   Created newsletter: #{tech_newsletter.title}"

  # Personal Newsletter
  personal_newsletter = Newsletter.create!(
    user: user,
    title: "#{user.name}'s Journal",
    description: "Personal thoughts, book reviews, and life updates."
  )
  puts "   Created newsletter: #{personal_newsletter.title}"
end

# Create team memberships
puts "\n-- Creating team memberships"
morpheus = User.find_by(email: "morpheus@example.com")
neo = User.find_by(email: "neo@example.com")

if morpheus && neo
  # Create Morpheus's special newsletter
  matrix_newsletter = Newsletter.create!(
    user: morpheus,
    title: "The Matrix Weekly",
    description: "Red pill insights into reality, technology, and the nature of existence."
  )
  puts "   Created newsletter: #{matrix_newsletter.title}"

  # Add Neo as an editor to Morpheus's newsletter
  Membership.create!(
    user: neo,
    newsletter: matrix_newsletter,
    role: :editor
  )
  puts "   Added #{neo.name} as editor to #{matrix_newsletter.title}"
end

# Create rich label structure for each newsletter
puts "\n-- Creating labels"
Newsletter.find_each do |newsletter|
  labels_data = [
    { name: "early-access", color: "#10B981", description: "Early access subscribers" },
    { name: "beta-tester", color: "#3B82F6", description: "Beta program participants" },
    { name: "premium", color: "#8B5CF6", description: "Premium tier subscribers" },
    { name: "inactive", color: "#EF4444", description: "Inactive subscribers" },
    { name: "engaged", color: "#F59E0B", description: "Highly engaged subscribers" },
    { name: "developer", color: "#059669", description: "Software developers" },
    { name: "designer", color: "#EC4899", description: "UI/UX designers" },
    { name: "manager", color: "#6366F1", description: "Tech managers & leaders" },
    { name: "student", color: "#14B8A6", description: "Students and learners" },
    { name: "vip", color: "#F59E0B", description: "VIP subscribers" }
  ]

  labels = newsletter.labels.create!(labels_data)
  puts "   Created #{labels.count} labels for #{newsletter.title}"
end

# Create posts for each newsletter
puts "\n-- Creating posts"
Newsletter.find_each do |newsletter|
  # Create posts with different statuses
  10.times do |i|
    title = if newsletter.title.include?("Tech")
      Faker::Hacker.say_something_smart
    else
      Faker::Book.title
    end

    status = case i % 5
    when 0 then :draft
    when 1, 2 then :published
    when 3 then :archived
    when 4 then :processing
    end

    published_at = status == :published ? rand(1..90).days.ago : nil
    content_md = Faker::Markdown.sandwich(sentences: 8)
    post = newsletter.posts.create!(
      title: title,
      content: Kramdown::Document.new(content_md).to_html,
      status: status,
      published_at: published_at
    )
    puts "   Created post: #{post.title} (#{status})"
  end
end

# Create subscribers for each newsletter
puts "\n-- Creating subscribers"
Newsletter.find_each do |newsletter|
  valid_labels = newsletter.labels.pluck(:name)

  # Create a mix of subscribers
  100.times do
    status = case rand(10)
    when 0..6 then :verified      # 70% verified
    when 7..8 then :unverified    # 20% unverified
    when 9 then :unsubscribed     # 10% unsubscribed
    end

    created_at = rand(1..180).days.ago
    verified_at = status == :verified ? created_at + rand(1..24).hours : nil
    unsubscribed_at = status == :unsubscribed ? created_at + rand(1..90).days : nil

    # Assign random labels (more likely for verified subscribers)
    subscriber_labels = if status == :verified && rand < 0.8
      valid_labels.sample(rand(1..4))
    else
      []
    end

    subscriber = newsletter.subscribers.create!(
      email: Faker::Internet.unique.email,
      full_name: Faker::Name.name,
      status: status,
      created_at: created_at,
      updated_at: created_at,
      verified_at: verified_at,
      unsubscribed_at: unsubscribed_at,
      labels: subscriber_labels,
      created_via: [ "web", "api", "import" ].sample,
      notes: rand < 0.3 ? Faker::Lorem.sentence : nil
    )
  end

  puts "   Created 100 subscribers for #{newsletter.title}"
end
# Create emails and engagement data
puts "\n-- Creating email engagement data"
Post.published.find_each do |post|
  # Get verified subscribers for this newsletter
  subscribers = post.newsletter.subscribers.verified

  subscribers.find_each do |subscriber|
    # Create email with random status and timing
    created_at = post.published_at + rand(1..12).hours

    status = case rand(100)
    when 0..84 then :delivered  # 85% delivered
    when 85..94 then :sent      # 10% just sent
    when 95..97 then :bounced   # 3% bounced
    else :complained            # 2% complained
    end

    email = post.emails.create!(
      id: SecureRandom.uuid,
      subscriber: subscriber,
      status: status,
      created_at: created_at,
      updated_at: created_at,
      opened_at: (status == :delivered && rand < 0.3) ? created_at + rand(1..24).hours : nil
    )
  end

  puts "   Created engagement data for post: #{post.title}"
end

# Create email clicks for opened emails
puts "\n-- Creating email click data"
Email.where.not(opened_at: nil).find_each do |email|
  # Generate 0-3 clicks per opened email (some emails have no clicks, some have multiple)
  click_count = rand(4)

  next if click_count == 0

  # Sample links that might appear in newsletters
  possible_links = [
    "https://example.com/article/#{rand(1000)}",
    "https://github.com/user/repo",
    "https://docs.example.com/guide",
    "https://blog.example.com/post/#{rand(100)}",
    "https://twitter.com/user/status/#{rand(1000000)}",
    "https://youtube.com/watch?v=#{SecureRandom.hex(5)}",
    "https://product.example.com/feature",
    "https://newsletter.example.com/archive"
  ]

  click_count.times do
    # Clicks happen after email is opened
    click_time = email.opened_at + rand(1..48).hours

    EmailClick.create!(
      email_id: email.id,
      post_id: email.emailable_id,
      link: possible_links.sample,
      timestamp: click_time
    )
  end
end

puts "   Created click data for opened emails"

puts "\nSeeding completed!"
