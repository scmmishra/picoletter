class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :newsletter, null: false, foreign_key: true
      t.string :role, null: false

      t.timestamps
    end

    add_index :memberships, [ :user_id, :newsletter_id ], unique: true
    add_index :memberships, :role
  end
end
