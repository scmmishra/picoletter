class AddSlugToPost < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :slug, :string, null: false
    add_index :posts, :slug
    add_index :posts, [ :newsletter_id, :slug ], unique: true
  end
end
