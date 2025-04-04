class SetDefaultEmptyJsonbForUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_default :users, :additional_data, from: nil, to: {}
    change_column_default :users, :limits, from: nil, to: {}
  end
end
