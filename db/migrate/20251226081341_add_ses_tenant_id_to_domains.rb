class AddSESTenantIdToDomains < ActiveRecord::Migration[8.1]
  def change
    add_column :domains, :ses_tenant_id, :string
    add_index :domains, :ses_tenant_id
  end
end
