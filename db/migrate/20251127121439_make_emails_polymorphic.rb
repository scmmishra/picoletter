class MakeEmailsPolymorphic < ActiveRecord::Migration[8.0]
  def up
    # Add polymorphic columns
    add_column :emails, :emailable_type, :string
    add_column :emails, :emailable_id, :bigint

    # Migrate existing data: all current emails belong to posts
    execute <<-SQL
      UPDATE emails
      SET emailable_type = 'Post', emailable_id = post_id
      WHERE post_id IS NOT NULL
    SQL

    # Add polymorphic index
    add_index :emails, [ :emailable_type, :emailable_id ]

    # Remove foreign key constraint on post_id before making it nullable
    remove_foreign_key :emails, :posts

    # Make post_id nullable
    change_column_null :emails, :post_id, true
  end

  def down
    # Restore data from polymorphic to post_id for Post types
    execute <<-SQL
      UPDATE emails
      SET post_id = emailable_id
      WHERE emailable_type = 'Post'
    SQL

    # Make post_id required again
    change_column_null :emails, :post_id, false

    # Re-add foreign key
    add_foreign_key :emails, :posts

    # Remove polymorphic index
    remove_index :emails, [ :emailable_type, :emailable_id ]

    # Remove polymorphic columns
    remove_column :emails, :emailable_id
    remove_column :emails, :emailable_type
  end
end
