class CreateNewsletters < ActiveRecord::Migration[7.1]
  def change
    create_table :newsletters do |t|
      t.string :title
      t.text :description
      t.references :user, null: false, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end
