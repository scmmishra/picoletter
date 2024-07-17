class AddNotesToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :notes, :text
  end
end
