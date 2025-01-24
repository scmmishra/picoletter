class AddBlockedAtAndRemoveActive < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :active, :boolean
    add_column :users, :blocked_at, :datetime, null: true
  end
end
