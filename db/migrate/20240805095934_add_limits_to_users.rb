class AddLimitsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :limits, :json
  end
end
