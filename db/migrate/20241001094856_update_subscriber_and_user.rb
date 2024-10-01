class UpdateSubscriberAndUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :limits, :jsonb
    add_column :users, :additional_data, :jsonb
    add_column :users, :verified_at, :datetime
    add_index :subscribers, :status
  end
end
