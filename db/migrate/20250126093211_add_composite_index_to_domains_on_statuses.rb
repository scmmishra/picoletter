class AddCompositeIndexToDomainsOnStatuses < ActiveRecord::Migration[8.0]
  def change
    add_index :domains, [ :status, :dkim_status, :spf_status ]
  end
end
