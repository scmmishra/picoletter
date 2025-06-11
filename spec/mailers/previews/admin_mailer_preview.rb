class AdminMailerPreview < ActionMailer::Preview
  # Define structs as constants outside the method
  DummyNewsletter = Struct.new(:title)
  DummyPost = Struct.new(:id, :title, :updated_at, :newsletter)

  def stuck_posts_alert
    stuck_posts = [
      DummyPost.new(
        123,
        "Weekly Newsletter #45",
        15.minutes.ago,
        DummyNewsletter.new("Tech Weekly")
      ),
      DummyPost.new(
        456,
        "Product Launch Announcement",
        25.minutes.ago,
        DummyNewsletter.new("StartupCorp Updates")
      )
    ]

    # Add includes method to mimic ActiveRecord relation
    def stuck_posts.includes(*args)
      self
    end

    AdminMailer.stuck_posts_alert(stuck_posts)
  end
end
