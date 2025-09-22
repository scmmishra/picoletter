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

    csv_data.each_with_index do |row, index|
      begin
        html_content = render_html_content(row)

        if dry_run
          puts "Would send to: #{row['email']}"
          puts "Subject: #{@subject}"
          puts "Template: #{@template_name}"
          puts "Data: #{row.to_h}"
          puts "---"
        else
          send_individual_email(row["email"], html_content)
          @sent_emails << { email: row["email"], data: row.to_h }
        end
      rescue => e
        @errors << { row: index + 1, email: row["email"], error: e.message, data: row.to_h }
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
    template.render("data" => data, "newsletter" => @newsletter.as_json)
  end

  def send_individual_email(email, html_content)
    email_service = SES::EmailService.new

    email_service.send(
      to: [ email ],
      from: @from_email,
      reply_to: @newsletter.reply_to || @from_email,
      subject: @subject,
      html: html_content,
      text: nil
    )
  end
end
