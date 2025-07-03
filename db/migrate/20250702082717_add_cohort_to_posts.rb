class AddCohortToPosts < ActiveRecord::Migration[8.0]
  def change
    add_reference :posts, :cohort, null: true, foreign_key: true
  end
end
