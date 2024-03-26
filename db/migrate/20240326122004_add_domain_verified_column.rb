class AddDomainVerifiedColumn < ActiveRecord::Migration[7.1]
  def change
    add_column :newsletters, :domain_verified, :boolean, default: false
  end
end
