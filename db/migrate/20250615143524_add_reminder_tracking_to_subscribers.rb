class AddReminderTrackingToSubscribers < ActiveRecord::Migration[8.0]
  def change
    add_column :subscribers, :additional_data, :jsonb, default: {}, null: false
    add_index :subscribers, :additional_data, using: :gin
    add_index :subscribers, "(additional_data->>'last_reminder_sent_at')",
              name: 'index_subscribers_on_reminder_sent_at'
  end
end
