# == Schema Information
#
# Table name: newsletters
#
#  id              :bigint           not null, primary key
#  description     :text
#  dns_records     :json
#  domain          :string
#  domain_verified :boolean          default(FALSE)
#  email_css       :text
#  email_footer    :text             default("")
#  enable_archive  :boolean          default(TRUE)
#  font_preference :string           default("sans-serif")
#  primary_color   :string           default("#09090b")
#  reply_to        :string
#  sending_address :string
#  sending_name    :string
#  settings        :jsonb            not null
#  slug            :string           not null
#  status          :string
#  template        :string
#  timezone        :string           default("UTC"), not null
#  title           :string
#  website         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  domain_id       :string
#  user_id         :integer          not null
#
# Indexes
#
#  index_newsletters_on_settings  (settings) USING gin
#  index_newsletters_on_slug      (slug)
#  index_newsletters_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Newsletter, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
