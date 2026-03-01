class AddUniqueIndexOnDomainsNewsletterId < ActiveRecord::Migration[8.0]
  def change
    remove_index :domains, :newsletter_id
    add_index :domains, :newsletter_id, unique: true
  end
end
