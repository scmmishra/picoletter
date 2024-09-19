class AddAnalyticsDataToSubscribers < ActiveRecord::Migration[7.2]
  def change
    add_column :subscribers, :analytics_data, :jsonb, default: {}
  end
end
