class CreateApiTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :api_tokens do |t|
      t.string :token, null: false
      t.jsonb :permissions, null: false, default: [ "subscription" ]
      t.references :newsletter, null: false, foreign_key: true

      t.timestamps
    end
    add_index :api_tokens, :token, unique: true
  end
end
