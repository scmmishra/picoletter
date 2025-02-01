class AddSendingNameToNewsletters < ActiveRecord::Migration[8.0]
  def change
    add_column :newsletters, :sending_name, :string
  end
end
