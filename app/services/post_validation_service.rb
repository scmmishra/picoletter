class PostValidationService
  include HTTParty

  def initialize(post)
    @post = post
  end

  def perform
    validate_links
  end

  private

  def validate_links
    content = @post.content.body.to_s
    doc = Nokogiri::HTML(content)
    links = doc.css("a")

    links.each do |link|
      url = link["href"]
      unless active_link?(url)
        raise Exceptions::InvalidLinkError, "Invalid link found: #{url}"
      end
    end
  end

  def active_link?(url, attempt = 1)
    raise "[PostValidationService] Too many connection resets" if attempt > 3

    response = HTTParty.head(url, follow_redirect: true)
    response.success?
  rescue Errno::ECONNRESET
    active_link?(url, attempt + 1)
  rescue HTTParty::ResponseError, SocketError, Net::OpenTimeout, Net::ReadTimeout
    false
  end
end
