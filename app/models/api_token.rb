# == Schema Information
#
# Table name: api_tokens
#
#  id            :bigint           not null, primary key
#  expires_at    :datetime
#  permissions   :jsonb            not null
#  token         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  newsletter_id :bigint           not null
#
# Indexes
#
#  index_api_tokens_on_newsletter_id  (newsletter_id)
#  index_api_tokens_on_token          (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
class ApiToken < ApplicationRecord
  belongs_to :newsletter

  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  def has_permission?(name)
    permissions.include?(name.to_s)
  end

  def regenerate!
    update!(token: self.class.generate_token_value)
  end

  private

  def generate_token
    self.token ||= self.class.generate_token_value
  end

  def self.generate_token_value
    "pcltr_#{SecureRandom.urlsafe_base64(32)}"
  end
end
