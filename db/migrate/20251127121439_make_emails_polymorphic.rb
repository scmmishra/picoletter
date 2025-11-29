class MakeEmailsPolymorphic < ActiveRecord::Migration[8.0]
  def change
    # Add polymorphic columns
    add_column :emails, :emailable_type, :string
    add_column :emails, :emailable_id, :bigint

    # Add polymorphic index
    add_index :emails, [ :emailable_type, :emailable_id ]

    # Remove foreign key constraint on post_id before making it nullable
    remove_foreign_key :emails, :posts

    # Make post_id nullable
    change_column_null :emails, :post_id, true

    # Migrate existing data: all current emails belong to posts
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE emails
          SET emailable_type = 'Post', emailable_id = post_id
          WHERE post_id IS NOT NULL
        SQL
      end
    end
  end
end
