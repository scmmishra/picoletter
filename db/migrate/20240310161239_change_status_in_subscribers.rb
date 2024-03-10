class ChangeStatusInSubscribers < ActiveRecord::Migration[7.1]
  def up
    change_column :subscribers, :status, :integer
  end

  def down
    change_column :subscribers, :status, :string
  end
end
