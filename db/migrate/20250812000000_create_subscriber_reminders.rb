class CreateSubscriberReminders < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriber_reminders do |t|
      t.references :subscriber, null: false, foreign_key: true
      t.integer :kind, null: false, default: 0
      t.string :message_id
      t.datetime :sent_at

      t.timestamps
    end

    add_index :subscriber_reminders, [ :subscriber_id, :kind ]
    add_index :subscriber_reminders, :message_id, unique: true
  end
end
