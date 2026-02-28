require "rails_helper"

RSpec.describe SendPostBatchJob, type: :job do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user) }
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
end
