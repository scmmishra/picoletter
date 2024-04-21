class AddDefaultValueToNewsletterFooter < ActiveRecord::Migration[7.1]
  def change
    change_column :newsletters, :email_footer, :text, default: ""
  end
end
