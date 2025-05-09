class CreateLabels < ActiveRecord::Migration[8.0]
  def change
    create_table :labels do |t|
      t.string :name, null: false
      t.text :description
      t.string :color, null: false, default: "#6B7280" # Default gray color
      t.references :newsletter, null: false, foreign_key: true

      t.timestamps
    end

    add_index :labels, [ :newsletter_id, :name ], unique: true
  end
end
