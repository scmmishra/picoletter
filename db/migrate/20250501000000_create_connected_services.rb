class CreateConnectedServices < ActiveRecord::Migration[8.0]
  def change
    create_table :connected_services do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false

      t.timestamps
    end

    add_index :connected_services, [ :provider, :uid ], unique: true
  end
end
