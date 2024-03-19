class AddIsSuperAdminToUser < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :is_superadmin, :boolean, default: false
    add_index :users, :is_superadmin
  end

  def down
    remove_index :users, :is_superadmin if index_exists?(:users, :is_superadmin)
    remove_column :users, :is_superadmin
  end
end
