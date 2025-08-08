module ColorsHelper
  def app_colors
    @app_colors ||= YAML.load_file(Rails.root.join("config", "colors.yml"))
  end
end
