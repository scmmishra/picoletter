class AddCustomDomainColumnsToNewsletter < ActiveRecord::Migration[7.1]
  def change
    add_column :newsletters, :use_custom_domain, :boolean
    add_column :newsletters, :domain, :string
    add_column :newsletters, :sending_address, :string
    add_column :newsletters, :reply_to, :string
    add_column :newsletters, :domain_verification_token, :string
  end
end
