# == Schema Information
#
# Table name: labels
#
#  id            :bigint           not null, primary key
#  color         :string           default("#6B7280"), not null
#  description   :text
#  name          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  newsletter_id :bigint           not null
#
# Indexes
#
#  index_labels_on_newsletter_id           (newsletter_id)
#  index_labels_on_newsletter_id_and_name  (newsletter_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
FactoryBot.define do
  factory :label do
    name { "MyString" }
    description { "MyText" }
    color { "MyString" }
    newsletter { nil }
  end
end
