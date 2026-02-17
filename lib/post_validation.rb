module PostValidation
  def self.validate_links!(post)
    content = post.content.body.to_s
    doc = Nokogiri::HTML(content)

    doc.css("a").each do |link|
      url = link["href"]
      unless active_link?(url)
        raise Exceptions::InvalidLinkError, "Invalid link found: #{url}"
      end
    end
  end

  def self.active_link?(url, attempt = 1)
    raise "[PostValidation] Too many connection resets" if attempt > 3

    response = HTTParty.head(url, follow_redirect: true)
    response.success?
  rescue Errno::ECONNRESET
    active_link?(url, attempt + 1)
  rescue HTTParty::ResponseError, SocketError, Net::OpenTimeout, Net::ReadTimeout
    false
  end

  private_class_method :active_link?
end
