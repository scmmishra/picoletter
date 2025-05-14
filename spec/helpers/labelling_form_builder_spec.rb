# frozen_string_literal: true

require "rails_helper"

RSpec.describe LabellingFormBuilder do
  include ActionView::Helpers::FormHelper
  include ActionView::Context

  # Test class that responds to all methods we need to test
  let(:model) do
    Class.new do
      attr_accessor :title, :email, :password, :description
      def self.model_name
        ActiveModel::Name.new(self, nil, "TestModel")
      end
    end.new
  end
  let(:builder) { LabellingFormBuilder.new(:test_model, model, self, {}) }

  describe "#text_field" do
    it "wraps with label and div" do
      result = builder.text_field(:title)
      expect(result).to include('class="space-y-1"')
      expect(result).to include('<label')
      expect(result).to include('Title')
      expect(result).to include('type="text"')
    end

    it "uses custom label text" do
      result = builder.text_field(:title, label: "Custom Title")
      expect(result).to include('Custom Title')
    end

    it "includes hint when provided" do
      result = builder.text_field(:title, hint: "Please enter a title")
      expect(result).to include('Please enter a title')
    end
  end

  describe "#text_area" do
    it "adds block class when specified" do
      result = builder.text_area(:description, block: true)
      expect(result).to include('class="input w-full block"')
      expect(result).to include('<textarea')
    end
  end

  describe "#email_field" do
    it "renders with correct type" do
      result = builder.email_field(:email)
      expect(result).to include('type="email"')
    end
  end

  describe "#password_field" do
    it "renders with correct type" do
      result = builder.password_field(:password)
      expect(result).to include('type="password"')
    end
  end
end
