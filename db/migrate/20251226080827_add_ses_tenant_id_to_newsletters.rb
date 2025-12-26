class AddSESTenantIdToNewsletters < ActiveRecord::Migration[8.1]
  def change
    add_column :newsletters, :ses_tenant_id, :string
    add_index :newsletters, :ses_tenant_id
  end
end
