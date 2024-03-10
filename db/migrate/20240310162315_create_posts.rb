class CreatePosts < ActiveRecord::Migration[7.1]
  def change
    create_table :posts do |t|
      t.string :title
      t.text :content
      t.references :newsletter, null: false, foreign_key: true
      t.datetime :scheduled_at
      t.string :status, default: "draft"
      t.datetime :published_at

      t.timestamps
    end
  end
end
