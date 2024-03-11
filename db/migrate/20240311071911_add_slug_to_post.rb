class AddSlugToPost < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :slug, :string, null: false, index: true
    add_index :posts, %i[newsletter_id slug], unique: true
  end
end
