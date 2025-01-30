class RebuildEmailsAndClicks < ActiveRecord::Migration[8.0]
  def change
    # Remove foreign keys first
    remove_foreign_key :email_clicks, :emails
    remove_foreign_key :emails, :posts
    remove_foreign_key :emails, :subscribers

    # Drop the tables
    drop_table :email_clicks
    drop_table :emails

    # Recreate emails table with string id
    create_table :emails, id: false do |t|
      t.string :id, primary_key: true
      t.bigint :post_id, null: false
      t.string :status, default: "sent"
      t.datetime :bounced_at
      t.datetime :delivered_at
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.integer :subscriber_id
      t.datetime :complained_at
      t.datetime :opened_at

      t.index :post_id
      t.index :subscriber_id
    end

    # Recreate email_clicks table
    create_table :email_clicks, force: :cascade do |t|
      t.string :link
      t.string :email_id, null: false
      t.bigint :post_id, null: false
      t.datetime :timestamp

      t.index :email_id
      t.index :post_id
    end

    # Add back foreign keys
    add_foreign_key :email_clicks, :emails
    add_foreign_key :emails, :posts
    add_foreign_key :emails, :subscribers
  end
end
