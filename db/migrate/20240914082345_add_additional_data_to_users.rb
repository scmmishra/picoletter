class AddAdditionalDataToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :additional_data, :jsonb
  end
end
