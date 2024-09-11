class AddComplainedAtAndClickedAtToEmails < ActiveRecord::Migration[7.2]
  def change
    add_column :emails, :complained_at, :datetime
    add_column :emails, :clicked_at, :datetime
  end
end
