module ApplicationHelper
  include Pagy::Frontend

  def labeled_form_with(**options, &block)
    options[:builder] = LabellingFormBuilder
    form_with(**options, &block)
  end

end
