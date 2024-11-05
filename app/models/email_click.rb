# == Schema Information
#
# Table name: email_clicks
#
#  id        :bigint           not null, primary key
#  link      :string
#  timestamp :datetime
#  email_id  :string           not null
#
# Indexes
#
#  index_email_clicks_on_email_id  (email_id)
#
# Foreign Keys
#
#  fk_rails_...  (email_id => emails.id)
#
class EmailClick < ApplicationRecord
end
