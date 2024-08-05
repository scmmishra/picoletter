# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  active          :boolean
#  bio             :text
#  email           :string           not null
#  is_superadmin   :boolean          default(FALSE)
#  limits          :json
#  name            :string
#  password_digest :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_is_superadmin  (is_superadmin)
#
require 'rails_helper'

RSpec.describe User, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
