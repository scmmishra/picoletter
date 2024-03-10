class ChangeVerifiedAtInSubscribers < ActiveRecord::Migration[7.1]
  def up
    change_column :subscribers, :verified_at, :datetime
  end

  def down
    change_column :subscribers, :verified_at, :boolean
  end
end
