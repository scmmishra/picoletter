# == Schema Information
#
# Table name: email_clicks
#
#  id       :bigint           not null, primary key
#  datetime :datetime
#  link     :string
#  email_id :string           not null
#
# Indexes
#
#  index_email_clicks_on_email_id  (email_id)
#
# Foreign Keys
#
#  fk_rails_...  (email_id => emails.id)
#
require 'rails_helper'

RSpec.describe EmailClick, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
