class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.references :newsletter, null: false, foreign_key: true
      t.string :email, null: false
      t.string :role, null: false, default: "editor"
      t.string :token, null: false
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.datetime :accepted_at
      t.datetime :expires_at, null: false, default: -> { "CURRENT_TIMESTAMP + interval '14 days'" }

      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations,
              [ :newsletter_id, Arel.sql("LOWER(email)") ],
              unique: true,
              where: "accepted_at IS NULL",
              name: "index_invitations_on_newsletter_and_lower_email"
  end
end
