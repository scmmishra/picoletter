module NewsletterHelper
  def newsletter_datetime(datetime, newsletter)
    return { date: "", time: "" } unless datetime

    in_zone = datetime.in_time_zone(newsletter.timezone)
    {
      date: in_zone.strftime("%B %d, %Y"),
      time: in_zone.strftime("%I:%M %p")
    }
  end
end
