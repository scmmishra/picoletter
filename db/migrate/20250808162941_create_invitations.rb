class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.references :newsletter, null: false, foreign_key: true
      t.string :email, null: false
      t.string :role, null: false, default: "editor"
      t.string :token, null: false
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.datetime :accepted_at
      t.timestamps
    end

    add_index :invitations, :token, unique: true
  end
end
