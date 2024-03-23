require "kramdown"
require 'faker'

scale = ENV['SCALE'] || 1
seed_perf = ENV['SEED_PERF'] || false

def parse_md_file(content)
  if content.start_with?("---")
    end_index = content.index("---", 3)
    if end_index
      yaml_content = content[3...end_index].strip
      frontmatter = YAML.load(yaml_content)

      body = content[end_index + 3..-1].strip.gsub('---', '')
      body_html = Kramdown::Document.new(body).to_html
      return [ frontmatter, body_html ]
    end
  end

  [ nil, nil ]
end


user = User.create!(
  name: "Neo Anderson",
  email: "neo@example.com",
  password: "admin@123456",
  is_superadmin: true
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
  frontmatter, html_content = parse_md_file(File.read(file))
  return if frontmatter.nil? || html_content.nil?

  title = frontmatter["title"]
  is_draft = frontmatter["draft"]

  created_at = publish_date - rand(1..3).days

  newsletter.posts.create!(
    title: title,
    content: html_content,
    published_at: is_draft ? nil : publish_date,
    created_at: created_at,
    updated_at: created_at,
    status: is_draft ? :draft : :published,
  )

  puts "  Created post #{title}"

  publish_date -= 1.week
end

subscribers = (50 * scale).times.map do
  email = Faker::Internet.email
  full_name = Faker::Name.name
  status = [ :verified, :verified, :verified, :verified, :verified, :verified, :verified, :unverified, :unverified, :unsubscribed ].sample
  created_at = Time.now - rand(1..3).months
  verified_at = (status == :verified || status == :unsubscribed) ? created_at + rand(1..30).hours : nil
  unsubscribed_at = (status == :unsubscribed) ? created_at + rand(1..30).days : nil

  {
    email: email,
    full_name: full_name,
    status: status,
    created_at: created_at,
    updated_at: created_at,
    verified_at: verified_at,
    unsubscribed_at: unsubscribed_at
  }
end

newsletter.subscribers.create!(subscribers)
puts "  Created #{subscribers.count} subscribers"

return unless seed_perf

password_digest = User.new(password: "admin@123456").password_digest

ActiveRecord::Base.transaction do
  users_data = 300.times.map do
    {
      name: Faker::Name.name,
      email: Faker::Internet.unique.email,
      password_digest: password_digest,
      active: true,
      bio: Faker::Lorem.paragraph
    }
  end

  users = User.insert_all(users_data)
end

puts "Created 300 users"


User.all.each do |user|
  next if user.email == 'neo@example.com'
  ActiveRecord::Base.transaction do
    number_of_newsletters = rand(1..5)
    newsletters_data = number_of_newsletters.times.map do
      title = Faker::Lorem.sentence(word_count: 3)

      {
        user_id: user['id'],
        slug: Faker::Internet.slug(words: title),
        title: title,
        description: Faker::Lorem.paragraph
      }
    end

    newsletters = Newsletter.insert_all(newsletters_data)

    newsletters.each do |newsletter|
      number_of_posts = rand(50..1000)
      posts_data = number_of_posts.times.map do
        title = Faker::Lorem.sentence(word_count: 5)

        {
          newsletter_id: newsletter['id'],
          title: title,
          slug: Faker::Internet.slug(words: title),
          content: Faker::Lorem.paragraph(sentence_count: 10),
          status: [ :draft, :published ].sample,
          published_at: Faker::Time.between(from: 1.year.ago, to: Time.now),
          created_at: Faker::Time.between(from: 1.year.ago, to: Time.now),
          updated_at: Faker::Time.between(from: 1.year.ago, to: Time.now)
        }
      end

      Post.insert_all(posts_data)
    end
    puts "Seeded #{user.email} with #{number_of_newsletters} newsletters"
  end
end
