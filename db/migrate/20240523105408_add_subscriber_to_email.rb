class AddSubscriberToEmail < ActiveRecord::Migration[7.1]
  def change
    add_reference :emails, :subscriber, null: true, foreign_key: true
  end
end
