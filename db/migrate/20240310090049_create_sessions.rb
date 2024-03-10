class CreateSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :sessions do |t|
      t.integer :user_id
      t.string :token
      t.boolean :active

      t.timestamps
    end
  end
end
