require "rails_helper"

RSpec.describe SendPostBatchJob, type: :job do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, :with_ready_ses_tenant, user: user) }
  let(:post) { create(:post, newsletter: newsletter, title: "Scheduled post") }
  let(:subscriber) { create(:subscriber, newsletter: newsletter) }

  describe "#perform" do
    it "stores sent emails via emailable polymorphic association" do
      job = described_class.new
      allow(job).to receive(:rendered_html_content).and_return("<p>hello</p>")
      allow(job).to receive(:rendered_text_content).and_return("hello")
      allow(job).to receive(:send_email).and_return(double(message_id: "ses-message-id-1"))

      expect {
        job.perform(post.id, [ subscriber.id ])
      }.to change(Email, :count).by(1)

      email = Email.find("ses-message-id-1")
      expect(email.emailable).to eq(post)
      expect(email.subscriber).to eq(subscriber)
    end

    it "accepts hash responses when extracting message ids" do
      job = described_class.new
      allow(job).to receive(:rendered_html_content).and_return("<p>hello</p>")
      allow(job).to receive(:rendered_text_content).and_return("hello")
      allow(job).to receive(:send_email).and_return({ message_id: "hash-message-id-1" })

      job.perform(post.id, [ subscriber.id ])

      expect(Email.find("hash-message-id-1").emailable).to eq(post)
    end

    it "supports previously-enqueued subscriber objects" do
      job = described_class.new
      allow(job).to receive(:rendered_html_content).and_return("<p>hello</p>")
      allow(job).to receive(:rendered_text_content).and_return("hello")
      allow(job).to receive(:send_email).and_return(double(message_id: "legacy-message-id-1"))

      job.perform(post.id, [ subscriber ])

      expect(Email.find("legacy-message-id-1").subscriber).to eq(subscriber)
    end
  end

  describe "unsubscribe headers" do
    it "puts the one-click URL first and includes a List-ID header" do
      job = described_class.new
      placeholder = described_class::UNSUBSCRIBE_PLACEHOLDER
      allow(job).to receive(:rendered_html_content).and_return("<p>Click #{placeholder}</p>")
      allow(job).to receive(:rendered_text_content).and_return("Click #{placeholder}")

      ses_service = instance_double(SES::EmailService)
      allow(SES::EmailService).to receive(:new).and_return(ses_service)
      allow(ses_service).to receive(:send).and_return(double(message_id: "ses-message-id-2"))

      job.perform(post.id, [ subscriber.id ], { tenant_name: newsletter.ses_tenant.name })

      expect(ses_service).to have_received(:send) do |params|
        headers = params.fetch(:headers)
        unsubscribe_parts = headers.fetch("List-Unsubscribe").split(",")
        expected_list_id = "<newsletter-#{newsletter.id}.#{newsletter.sending_from.split('@').last}>"

        expect(unsubscribe_parts.first).to include("/#{newsletter.slug}/unsubscribe?token=")
        expect(unsubscribe_parts.first).to start_with("<http")
        expect(unsubscribe_parts.last).to start_with("<mailto:")
        expect(headers["List-Unsubscribe-Post"]).to eq("List-Unsubscribe=One-Click")
        expect(headers["List-ID"]).to eq(expected_list_id)
        expect(params[:tenant_name]).to eq(newsletter.ses_tenant.name)
      end
    end
  end

  describe "failure handling" do
    it "marks the post failed when a send attempt raises" do
      post.update!(status: "processing")
      job = described_class.new
      allow(job).to receive(:rendered_html_content).and_return("<p>hello</p>")
      allow(job).to receive(:rendered_text_content).and_return("hello")
      allow(job).to receive(:send_email).and_raise(StandardError.new("SES failed"))

      expect(Rails.error).to receive(:report).with(
        an_instance_of(StandardError),
        hash_including(context: hash_including(post_id: post.id, newsletter_id: newsletter.id))
      )

      expect {
        job.perform(post.id, [ subscriber.id ], { tenant_name: newsletter.ses_tenant.name })
      }.to raise_error(StandardError, "SES failed")

      expect(post.reload.status).to eq("failed")
    end
  end

  describe "HTML rendering" do
    it "inlines critical publish styles for email clients" do
      post.update!(
        content: <<~HTML
          <figure class="lexxy-content__table-wrapper">
            <table>
              <tbody>
                <tr>
                  <th class="lexxy-content__table-cell--header"><p>Feature</p></th>
                  <td><p>Value</p></td>
                </tr>
              </tbody>
            </table>
          </figure>
          <pre data-language="plain">hello</pre>
        HTML
      )

      html = described_class.new.send(:render_html_content, post, newsletter)
      document = Nokogiri::HTML.parse(html)

      container = document.at_css("div.container")
      expect(container).to be_present
      expect(container["style"]).to include("max-width: 600px")

      table = document.at_css("div.content table")
      expect(table).to be_present
      expect(table["style"]).to include("border-collapse: collapse")

      header_cell = document.at_css("div.content th.lexxy-content__table-cell--header")
      expect(header_cell).to be_present
      expect(header_cell["style"]).to include("font-weight: 700")
      expect(header_cell["style"]).to include("border: 1px solid #e7e5e4")

      code_block = document.at_css("div.content pre[data-language]")
      expect(code_block).to be_present
      expect(code_block["style"]).to include("border: 1px solid #e7e5e4")
      expect(code_block["style"]).to include("background-color: #fafaf9")
    end
  end
end
