class AddSettingsToNewsletters < ActiveRecord::Migration[8.0]
  def change
    add_column :newsletters, :settings, :jsonb, null: false, default: {}
    add_index :newsletters, :settings, using: :gin
  end
end