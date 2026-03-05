class CreateSESTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :ses_tenants do |t|
      t.references :newsletter, null: false, foreign_key: true
      t.string :name, null: false
      t.string :arn
      t.string :status, null: false, default: "pending"
      t.text :last_error
      t.datetime :last_checked_at
      t.datetime :last_synced_at
      t.datetime :ready_at

      t.timestamps
    end
  end
end
