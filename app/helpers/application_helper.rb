module ApplicationHelper
  include Pagy::Frontend

  def labeled_form_with(**options, &block)
    # Extract permission and check if form should be readonly
    permission = options.delete(:permission)
    if permission && @newsletter
      options[:readonly] = !@newsletter.can_write?(permission)
    end

    options[:builder] = LabellingFormBuilder
    form_with(**options, &block)
  end
end
