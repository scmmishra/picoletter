class AddIndexOnPostsStatusAndScheduledAt < ActiveRecord::Migration[8.1]
  def change
    add_index :posts, [ :status, :scheduled_at ], if_not_exists: true
  end
end
