class CreateEmails < ActiveRecord::Migration[7.1]
  def change
    create_table :emails do |t|
      t.references :post, null: false, foreign_key: true, type: :bigint
      t.string :email_id
      t.string :status, default: "sent"
      t.datetime :bounced_at, null: true
      t.datetime :delivered_at, null: true

      t.timestamps
    end
  end
end
