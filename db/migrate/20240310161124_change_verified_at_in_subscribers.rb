class ChangeVerifiedAtInSubscribers < ActiveRecord::Migration[7.1]
  def up
    remove_column :subscribers, :verified_at
    add_column :subscribers, :verified_at, :datetime
  end

  def down
    remove_column :subscribers, :verified_at
    add_column :subscribers, :verified_at, :boolean
  end
end
