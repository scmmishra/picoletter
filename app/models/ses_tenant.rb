# == Schema Information
#
# Table name: ses_tenants
# Database name: primary
#
#  id              :bigint           not null, primary key
#  arn             :string
#  last_checked_at :datetime
#  last_error      :text
#  last_synced_at  :datetime
#  name            :string           not null
#  ready_at        :datetime
#  status          :string           default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  newsletter_id   :bigint           not null
#
# Indexes
#
#  index_ses_tenants_on_name           (name) UNIQUE
#  index_ses_tenants_on_newsletter_id  (newsletter_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
class SESTenant < ApplicationRecord
  belongs_to :newsletter

  enum :status,
    { pending: "pending", ready: "ready", failed: "failed", disabled: "disabled" },
    default: :pending

  validates :name, presence: true, uniqueness: true

  scope :active, -> { where.not(status: :disabled) }

  def usable_for_send?
    ready? && name.present?
  end

  def self.generate_name(newsletter_id)
    "picoletter-newsletter-#{newsletter_id}"
  end
end
