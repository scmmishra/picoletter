class AddUnSubscribedAtToSubscriber < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :unsubscribed_at, :datetime
  end
end
