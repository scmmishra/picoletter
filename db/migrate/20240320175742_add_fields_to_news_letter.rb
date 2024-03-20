class AddFieldsToNewsLetter < ActiveRecord::Migration[7.1]
  def change
    add_column :newsletters, :timezone, :string, default: 'UTC', null: false
    add_column :newsletters, :template, :string
    add_column :newsletters, :website, :string
    add_column :newsletters, :email_css, :text
  end
end
