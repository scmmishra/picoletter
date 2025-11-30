module Templatable
  extend ActiveSupport::Concern

  TEMPLATES = %w[slate editorial].freeze
  DEFAULT_TEMPLATE = "slate".freeze

  included do
    validates :template, inclusion: { in: TEMPLATES }, allow_blank: true
  end

  def template_name
    template.presence || DEFAULT_TEMPLATE
  end

  def template_partial(view)
    "public/newsletters/templates/#{template_name}/#{view}"
  end
end
