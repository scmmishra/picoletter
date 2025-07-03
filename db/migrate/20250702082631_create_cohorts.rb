class CreateCohorts < ActiveRecord::Migration[8.0]
  def change
    create_table :cohorts do |t|
      t.string :name, null: false
      t.text :description
      t.string :emoji
      t.jsonb :filter_conditions, null: false, default: '{}'
      t.references :newsletter, null: false, foreign_key: true

      t.timestamps
    end

    add_index :cohorts, [ :newsletter_id, :name ], unique: true
    add_index :cohorts, :filter_conditions, using: :gin
  end
end
