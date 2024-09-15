class AddIndexToSubscribersStatus < ActiveRecord::Migration[7.2]
  def change
    add_index :subscribers, :status
  end
end
