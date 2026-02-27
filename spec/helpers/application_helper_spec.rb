require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#email_css_color" do
    it "converts 6-digit hex colors to rgb()" do
      expect(helper.email_css_color("#84CC16")).to eq("rgb(132, 204, 22)")
    end

    it "converts 3-digit hex colors to rgb()" do
      expect(helper.email_css_color("#abc")).to eq("rgb(170, 187, 204)")
    end

    it "returns non-hex values unchanged" do
      expect(helper.email_css_color("rgb(1, 2, 3)")).to eq("rgb(1, 2, 3)")
    end

    it "uses fallback for blank values and normalizes fallback hex" do
      expect(helper.email_css_color(nil, fallback: "#09090B")).to eq("rgb(9, 9, 11)")
    end

    it "uses fallback for blank values and preserves non-hex fallback" do
      expect(helper.email_css_color("", fallback: "black")).to eq("black")
    end
  end

  describe "#highlight_email_code_blocks" do
    it "returns blank content unchanged" do
      expect(helper.highlight_email_code_blocks(nil)).to be_nil
      expect(helper.highlight_email_code_blocks("")).to eq("")
    end

    it "adds inline link color and underline styles" do
      html = '<p><a href="https://example.com">Example</a></p>'

      result = helper.highlight_email_code_blocks(html, accent_color: "rgb(132, 204, 22)")

      expect(result).to include('href="https://example.com"')
      expect(result).to include('style="color: rgb(132, 204, 22); text-decoration: underline;"')
    end

    it "preserves existing link style and appends accent styles" do
      html = '<a href="https://example.com" style="font-weight: 700;">Example</a>'

      result = helper.highlight_email_code_blocks(html, accent_color: "#111111")

      expect(result).to include('style="font-weight: 700; color: #111111; text-decoration: underline;"')
    end

    it "highlights pre blocks with data-language and handles br as newlines" do
      html = '<pre data-language="javascript">let x = 1;<br>alert(x);</pre>'

      result = helper.highlight_email_code_blocks(html)

      expect(result).to include("let")
      expect(result).to include("alert")
      expect(result).to include("<span")
      expect(result).not_to include("<br>")
    end

    it "leaves pre blocks without data-language unhighlighted" do
      html = "<pre>no language</pre>"

      result = helper.highlight_email_code_blocks(html)

      expect(result).to include("<pre>no language</pre>")
      expect(result).not_to include("<span")
    end

    it "returns original content if parsing fails" do
      html = "<p>hello</p>"
      allow(Nokogiri::HTML::DocumentFragment).to receive(:parse).and_raise(StandardError, "boom")

      expect(helper.highlight_email_code_blocks(html)).to eq(html)
    end
  end
end
