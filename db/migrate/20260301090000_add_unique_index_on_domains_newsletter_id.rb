class AddUniqueIndexOnDomainsNewsletterId < ActiveRecord::Migration[8.0]
  def up
    remove_index :domains, :newsletter_id if index_exists?(:domains, :newsletter_id, unique: false)
    add_index :domains, :newsletter_id, unique: true unless index_exists?(:domains, :newsletter_id, unique: true)
  end

  def down
    remove_index :domains, :newsletter_id if index_exists?(:domains, :newsletter_id, unique: true)
    add_index :domains, :newsletter_id unless index_exists?(:domains, :newsletter_id, unique: false)
  end
end
