class AddSlugToNewsletter < ActiveRecord::Migration[7.1]
  def change
    add_column :newsletters, :slug, :string, null: false, index: true
  end
end
