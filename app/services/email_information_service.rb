# based on MIT Licensed https://github.com/fnando/email-provider-info/
class EmailInformationService
  attr_reader :name, :url

  def initialize(email)
    host = email.to_s.downcase.split("@").last
    @provider = providers.find { |provider| provider["hosts"].include?(host) }

    return unless @provider.present?

    @name = @provider["name"]
    @url = @provider["url"]
    @email = email
    @search = @provider["search"]
  end

  def providers
    YAML.load_file(File.join(__dir__, "/data/providers.yml"))
  end

  def search_url(sender: nil)
    @search
      .gsub("%{sender}", CGI.escapeURIComponent(sender.to_s))
      .gsub("%{email}", CGI.escapeURIComponent(@email.to_s))
      .gsub("%{timestamp}", (Time.now.to_i - 3600).to_s)
  end
end
