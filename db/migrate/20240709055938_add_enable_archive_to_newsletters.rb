class AddEnableArchiveToNewsletters < ActiveRecord::Migration[7.1]
  def change
    add_column :newsletters, :enable_archive, :boolean
  end
end
