class AddUniqueIndexesToSESTenants < ActiveRecord::Migration[8.1]
  def change
    remove_index :ses_tenants, :newsletter_id, if_exists: true
    add_index :ses_tenants, :newsletter_id, unique: true
    add_index :ses_tenants, :name, unique: true, if_not_exists: true
  end
end
