class AddAutoReminderEnabledToNewsletters < ActiveRecord::Migration[8.0]
  def change
    add_column :newsletters, :auto_reminder_enabled, :boolean, default: true, null: false
  end
end
