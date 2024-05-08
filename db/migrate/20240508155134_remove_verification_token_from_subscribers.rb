class RemoveVerificationTokenFromSubscribers < ActiveRecord::Migration[7.1]
  def change
    remove_column :subscribers, :verification_token, :string
  end
end
