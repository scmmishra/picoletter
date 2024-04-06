class AddDomainIdAndDNSRecordsFieldToNewsletter < ActiveRecord::Migration[7.1]
  def change
    add_column :newsletters, :domain_id, :string
    add_column :newsletters, :dns_records, :json
  end
end
