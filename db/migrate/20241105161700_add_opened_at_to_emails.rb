class AddOpenedAtToEmails < ActiveRecord::Migration[8.0]
  def change
    add_column :emails, :opened_at, :datetime
  end
end
