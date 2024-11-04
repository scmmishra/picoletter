# == Schema Information
#
# Table name: email_clicks
#
#  id         :bigint           not null, primary key
#  link       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  email_id   :string           not null
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
