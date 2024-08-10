class AddReferrerUrlAndUtmToSubscribers < ActiveRecord::Migration[7.2]
  def change
    add_column :subscribers, :referrer_url, :string
    add_column :subscribers, :utm_source, :string
    add_column :subscribers, :utm_medium, :string
    add_column :subscribers, :utm_campaign, :string
  end
end
