class CreatePublishingDomains < ActiveRecord::Migration[8.0]
  def change
    create_table :publishing_domains do |t|
      t.references :newsletter, null: false, index: { unique: true }
      t.string :hostname, null: false
      t.string :domain_type, null: false, default: "custom_cname"
      t.string :status, null: false, default: "pending"
      t.string :cloudflare_id
      t.string :cloudflare_ssl_status
      t.string :verification_method
      t.string :verification_http_path
      t.text :verification_http_body
      t.datetime :verified_at
      t.text :last_error

      t.timestamps
    end

    add_index :publishing_domains, :hostname, unique: true
  end
end
