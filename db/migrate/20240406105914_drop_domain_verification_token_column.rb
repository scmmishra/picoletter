class DropDomainVerificationTokenColumn < ActiveRecord::Migration[7.1]
  def change
    remove_column :newsletters, :domain_verification_token, :string
  end
end
