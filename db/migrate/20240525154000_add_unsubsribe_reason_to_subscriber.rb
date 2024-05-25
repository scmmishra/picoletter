class AddUnsubsribeReasonToSubscriber < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :unsubscribe_reason, :string
  end
end
