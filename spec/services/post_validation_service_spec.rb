require "rails_helper"

RSpec.describe PostValidationService do
  describe "#perform" do
    context "when all links respond successfully" do
      let(:post) do
        create(:post).tap do |record|
          record.content = <<~HTML
            <p>
              <a href="https://example.com/ok">Ok</a>
              <a href="https://example.com/also-ok">Also Ok</a>
            </p>
          HTML
          record.save!
        end
      end

      let(:success_response) { instance_double(HTTParty::Response, success?: true) }

      before do
        allow(HTTParty).to receive(:head).and_return(success_response)
      end

      it "checks every link using a HEAD request and does not raise an error" do
        service = described_class.new(post)

        expect { service.perform }.not_to raise_error
        expect(HTTParty).to have_received(:head).with("https://example.com/ok", follow_redirect: true)
        expect(HTTParty).to have_received(:head).with("https://example.com/also-ok", follow_redirect: true)
      end
    end

    context "when a link responds unsuccessfully" do
      let(:post) do
        create(:post).tap do |record|
          record.content = <<~HTML
            <p>
              <a href="https://example.com/ok">Ok</a>
              <a href="https://example.com/broken">Broken</a>
            </p>
          HTML
          record.save!
        end
      end

      let(:success_response) { instance_double(HTTParty::Response, success?: true) }
      let(:failure_response) { instance_double(HTTParty::Response, success?: false) }

      it "raises an InvalidLinkError identifying the failing URL" do
        expect(HTTParty).to receive(:head)
          .with("https://example.com/ok", follow_redirect: true)
          .and_return(success_response)

        expect(HTTParty).to receive(:head)
          .with("https://example.com/broken", follow_redirect: true)
          .and_return(failure_response)

        service = described_class.new(post)

        expect { service.perform }
          .to raise_error(Exceptions::InvalidLinkError, "Invalid link found: https://example.com/broken")
      end
    end

    context "when HTTParty raises a timeout error" do
      let(:post) do
        create(:post).tap do |record|
          record.content = <<~HTML
            <p><a href="https://example.com/slow">Slow</a></p>
          HTML
          record.save!
        end
      end

      it "treats the link as inactive and raises an InvalidLinkError" do
        expect(HTTParty).to receive(:head)
          .with("https://example.com/slow", follow_redirect: true)
          .and_raise(Net::ReadTimeout)

        service = described_class.new(post)

        expect { service.perform }
          .to raise_error(Exceptions::InvalidLinkError, "Invalid link found: https://example.com/slow")
      end
    end

    context "when the request keeps hitting connection resets" do
      let(:post) do
        create(:post).tap do |record|
          record.content = <<~HTML
            <p><a href="https://example.com/flaky">Flaky</a></p>
          HTML
          record.save!
        end
      end

      it "retries up to three times and then raises an error" do
        expect(HTTParty).to receive(:head)
          .with("https://example.com/flaky", follow_redirect: true)
          .exactly(3).times
          .and_raise(Errno::ECONNRESET)

        service = described_class.new(post)

        expect { service.perform }
          .to raise_error(RuntimeError, "[PostValidationService] Too many connection resets")
      end
    end
  end
end
