class CreateEmailClicks < ActiveRecord::Migration[8.0]
  def change
    create_table :email_clicks do |t|
      t.string :link
      t.references :email, null: false, foreign_key: true, type: :string
      t.timestamp :datetime
    end
  end
end
