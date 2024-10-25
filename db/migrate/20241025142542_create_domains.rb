class CreateDomains < ActiveRecord::Migration[8.0]
  def change
    create_table :domains do |t|
      t.string :name
      t.references :newsletter, null: false, foreign_key: true
      t.string :status, default: "pending"
      t.string :region, default: 'us-east-1'
      t.string :public_key
      t.string :dkim_status
      t.string :spf_details
      t.string :error_message
      t.boolean :dmarc_added, default: false
      t.boolean :is_verifying, default: false

      t.timestamps
    end

    add_index :domains, :name, unique: true
  end
end
