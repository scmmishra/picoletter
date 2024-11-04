class AddIndexToEmails < ActiveRecord::Migration[8.0]
  def change
    add_index :emails, :email_id, unique: true
  end
end
