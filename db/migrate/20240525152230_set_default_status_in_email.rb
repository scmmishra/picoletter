class SetDefaultStatusInEmail < ActiveRecord::Migration[7.1]
  def change
    # set default status to sent
    change_column_default :emails, :status, "sent"
  end
end

