class AddVerifiedAtToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :verified_at, :datetime
  end
end
