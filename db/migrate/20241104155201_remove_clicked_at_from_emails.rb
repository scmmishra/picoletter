class RemoveClickedAtFromEmails < ActiveRecord::Migration[8.0]
  def change
    remove_column :emails, :clicked_at, :datetime
  end
end
