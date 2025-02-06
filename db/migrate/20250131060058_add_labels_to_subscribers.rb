class AddLabelsToSubscribers < ActiveRecord::Migration[8.0]
  def change
    add_column :subscribers, :labels, :string, array: true, default: []
    add_index :subscribers, :labels, using: 'gin'
  end
end
