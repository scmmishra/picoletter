class UpdateEmailTable < ActiveRecord::Migration[8.0]
  def change
    remove_column :emails, :email_id, :string
    change_column :emails, :id, :string
  end
end
