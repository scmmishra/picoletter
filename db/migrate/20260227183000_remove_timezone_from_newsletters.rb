class RemoveTimezoneFromNewsletters < ActiveRecord::Migration[8.1]
  def change
    remove_column :newsletters, :timezone, :string
  end
end
