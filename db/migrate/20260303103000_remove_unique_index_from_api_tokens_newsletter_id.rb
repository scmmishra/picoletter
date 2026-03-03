class RemoveUniqueIndexFromApiTokensNewsletterId < ActiveRecord::Migration[8.1]
  INDEX_NAME = "index_api_tokens_on_newsletter_id".freeze

  def up
    remove_index :api_tokens, name: INDEX_NAME if index_exists?(:api_tokens, :newsletter_id, name: INDEX_NAME, unique: true)
    add_index :api_tokens, :newsletter_id, name: INDEX_NAME unless index_exists?(:api_tokens, :newsletter_id, name: INDEX_NAME, unique: false)
  end

  def down
    remove_index :api_tokens, name: INDEX_NAME if index_exists?(:api_tokens, :newsletter_id, name: INDEX_NAME, unique: false)
    add_index :api_tokens, :newsletter_id, name: INDEX_NAME, unique: true unless index_exists?(:api_tokens, :newsletter_id, name: INDEX_NAME, unique: true)
  end
end
