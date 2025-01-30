# == Schema Information
#
# Table name: email_clicks
#
#  id        :integer          not null, primary key
#  link      :string
#  email_id  :string           not null
#  post_id   :integer          not null
#  timestamp :datetime
#
# Indexes
#
#  index_email_clicks_on_email_id  (email_id)
#  index_email_clicks_on_post_id   (post_id)
#

class EmailClick < ApplicationRecord
end
