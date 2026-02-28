class ChangeDomainsPublicKeyToText < ActiveRecord::Migration[8.0]
  def change
    change_column :domains, :public_key, :text
  end
end
