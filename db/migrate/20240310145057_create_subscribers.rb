class CreateSubscribers < ActiveRecord::Migration[7.1]
  def change
    create_table :subscribers do |t|
      t.string :email
      t.string :full_name
      t.references :newsletter, null: false, foreign_key: true
      t.string :created_via
      t.boolean :verified_at
      t.string :verification_token
      t.string :status

      t.timestamps
    end
  end
end
