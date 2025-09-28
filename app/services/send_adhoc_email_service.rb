class SendAdhocEmailService
  def initialize(newsletter_id, template_name, subject, csv_file)
    @newsletter = Newsletter.find(newsletter_id)
    @template_name = template_name
    @subject = subject
    @csv_file = csv_file
    @from_email = @newsletter.full_sending_address
    @sent_emails = []
    @errors = []
  end

  def validate_template
    # Read CSV and validate template rendering for each row
    csv_data = parse_csv
    csv_data.each_with_index do |row, index|
      begin
        render_html_content(row)
      rescue => e
        @errors << { row: index + 1, error: e.message, data: row }
      end
    end

    @errors.empty?
  end

  def send_emails(dry_run: false)
    csv_data = parse_csv

    if dry_run
      # For dry run, only process the first valid row
      first_valid_row = csv_data.find { |row| row[:email]&.strip&.present? }
      if first_valid_row
        email = first_valid_row[:email].strip
        html_content = render_html_content(first_valid_row)

        puts "✓ Would send to: #{email}"
        puts "  Subject: #{@subject}"
        puts "  Data: #{first_valid_row.to_h}"
        puts "\nRendered HTML:"
        puts "=" * 50
        puts html_content
        puts "=" * 50
      else
        puts "✗ No valid rows found with email addresses"
      end

      return { sent: 0, errors: [] }
    end

    csv_data.each_with_index do |row, index|
      begin
        # Validate email field
        email = row[:email]&.strip
        if email.blank?
          @errors << { row: index + 1, email: "blank", error: "Email field is missing or empty", data: row.to_h }
          next
        end

        html_content = render_html_content(row)
        send_individual_email(email, html_content)
        @sent_emails << { email: email, data: row.to_h }
      rescue => e
        @errors << { row: index + 1, email: row[:email] || "unknown", error: e.message, data: row.to_h }
      end
    end

    { sent: @sent_emails.count, errors: @errors }
  end

  private

  def parse_csv
    require "csv"
    CSV.foreach(@csv_file, headers: true, header_converters: :symbol).map(&:to_h)
  end

  def render_html_content(data)
    template_path = Rails.root.join("#{@template_name}.liquid")
    template_content = File.read(template_path)

    require "liquid"
    template = Liquid::Template.parse(template_content)
    # Convert symbol keys to string keys for Liquid
    data_with_string_keys = data.transform_keys(&:to_s)
    render_data = { "data" => data_with_string_keys, "newsletter" => @newsletter.as_json }
    template.render(render_data)
  end

  def send_individual_email(email, html_content)
    email_service = SES::EmailService.new

    email_service.send(
      to: [ email ],
      from: @from_email,
      reply_to: @newsletter.reply_to || @from_email,
      subject: @subject,
      html: html_content,
      text: ""
    )
  end
end
