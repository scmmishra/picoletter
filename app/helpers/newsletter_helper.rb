module NewsletterHelper
  def newsletter_datetime(datetime, _newsletter = nil)
    return { date: "", time: "" } unless datetime

    in_utc = datetime.utc
    {
      date: in_utc.strftime("%B %d, %Y"),
      time: in_utc.strftime("%I:%M %p UTC")
    }
  end
end
