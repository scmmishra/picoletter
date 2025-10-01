class CleanupNewsletterDomainColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :newsletters, :domain, :string
    remove_column :newsletters, :domain_verified, :boolean, default: false
  end
end
