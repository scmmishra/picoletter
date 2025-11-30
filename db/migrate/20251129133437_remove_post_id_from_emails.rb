class RemovePostIdFromEmails < ActiveRecord::Migration[8.1]
  def change
    remove_index :emails, :post_id
    remove_column :emails, :post_id, :bigint
  end
end
