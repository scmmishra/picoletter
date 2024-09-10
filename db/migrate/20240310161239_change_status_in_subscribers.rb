class ChangeStatusInSubscribers < ActiveRecord::Migration[7.1]
  def change
    remove_column :subscribers, :status
    add_column :subscribers, :status, :integer
  end
end
