require 'rails_helper'

RSpec.describe SendPostBatchJob, type: :job do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user, sending_address: "test@example.com", sending_name: "Test Newsletter") }
  let(:post) { create(:post, newsletter: newsletter, title: "Test Post") }
  let(:subscriber) { create(:subscriber, newsletter: newsletter, email: "subscriber@example.com") }
  let(:mock_ses_service) { double("SES::EmailService") }
  let(:mock_response) { double(message_id: "mock-message-id-123") }

  before do
    allow(SES::EmailService).to receive(:new).and_return(mock_ses_service)
    allow(mock_ses_service).to receive(:send).and_return(mock_response)

    # Mock rendered content to avoid ActionText rendering issues
    allow_any_instance_of(SendPostBatchJob).to receive(:rendered_html_content).and_return("<p>HTML content</p>")
    allow_any_instance_of(SendPostBatchJob).to receive(:rendered_text_content).and_return("Text content")

    # Mock email creation to focus on testing tenant_name logic
    allow_any_instance_of(ActiveRecord::Associations::HasManyAssociation).to receive(:create!)

    # Mock Rails cache for batch counting
    allow(Rails.cache).to receive(:decrement).and_return(0)
  end

  describe "#tenant_name_for_send" do
    context "when newsletter has verified custom domain" do
      before do
        newsletter.update!(ses_tenant_id: "newsletter-123-abc456")
        allow(newsletter).to receive(:ses_verified?).and_return(true)
      end

      it "returns the tenant_id" do
        job = SendPostBatchJob.new
        job.instance_variable_set(:@newsletter, newsletter)

        expect(job.send(:tenant_name_for_send)).to eq("newsletter-123-abc456")
      end
    end

    context "when newsletter does not have verified custom domain" do
      before do
        newsletter.update!(ses_tenant_id: "newsletter-123-abc456")
        allow(newsletter).to receive(:ses_verified?).and_return(false)
      end

      it "returns nil" do
        job = SendPostBatchJob.new
        job.instance_variable_set(:@newsletter, newsletter)

        expect(job.send(:tenant_name_for_send)).to be_nil
      end
    end

    context "when newsletter has no tenant_id" do
      before do
        newsletter.update!(ses_tenant_id: nil)
        allow(newsletter).to receive(:ses_verified?).and_return(true)
      end

      it "returns nil" do
        job = SendPostBatchJob.new
        job.instance_variable_set(:@newsletter, newsletter)

        expect(job.send(:tenant_name_for_send)).to be_nil
      end
    end
  end

  describe "#send_email" do
    context "when sending with verified custom domain and tenant" do
      before do
        newsletter.update!(ses_tenant_id: "newsletter-123-abc456")
        domain = create(:domain, newsletter: newsletter, name: "example.com", ses_tenant_id: "newsletter-123-abc456")
        domain.update!(status: "success", dkim_status: "success", spf_status: "success")
      end

      it "includes tenant_name in the send call" do
        expect(mock_ses_service).to receive(:send) do |params|
          expect(params[:tenant_name]).to eq("newsletter-123-abc456")
          mock_response
        end

        SendPostBatchJob.perform_now(post.id, [ subscriber ])
      end
    end

    context "when sending with default domain (no verified custom domain)" do
      before do
        newsletter.update!(ses_tenant_id: "newsletter-123-abc456")
        # No domain created, so ses_verified? will be false
      end

      it "does not include tenant_name in the send call" do
        expect(mock_ses_service).to receive(:send) do |params|
          expect(params[:tenant_name]).to be_nil
          mock_response
        end

        SendPostBatchJob.perform_now(post.id, [ subscriber ])
      end
    end

    context "when newsletter has no tenant" do
      before do
        newsletter.update!(ses_tenant_id: nil)
      end

      it "does not include tenant_name in the send call" do
        expect(mock_ses_service).to receive(:send) do |params|
          expect(params[:tenant_name]).to be_nil
          mock_response
        end

        SendPostBatchJob.perform_now(post.id, [ subscriber ])
      end
    end
  end
end
