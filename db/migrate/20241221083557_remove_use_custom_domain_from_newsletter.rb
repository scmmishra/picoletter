class RemoveUseCustomDomainFromNewsletter < ActiveRecord::Migration[8.0]
  def change
    remove_column :newsletters, :use_custom_domain, :boolean
  end
end
