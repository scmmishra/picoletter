class AddStyleFieldsToNewsLetter < ActiveRecord::Migration[7.1]
  def change
    add_column :newsletters, :primary_color, :string, default: "#09090b"
    add_column :newsletters, :font_preference, :string, default: "sans-serif"
    add_column :newsletters, :email_footer, :string
  end
end
