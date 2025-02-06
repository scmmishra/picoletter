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
class Label < ApplicationRecord
  belongs_to :newsletter

  attr_accessor :original_name

  before_validation :format_name
  before_save :format_color

  validates :name, presence: true, uniqueness: { scope: :newsletter_id, case_sensitive: false }
  validates :color, presence: true, format: { with: /\A#(?:[0-9a-fA-F]{3}){1,2}\z/, message: "must be a valid hex color code" }

  private

  def format_name
    return unless name
    # Convert to kebab case
    self.name = name.downcase
                   .gsub(/[^a-z0-9\s-]/, "") # Remove invalid chars
                   .gsub(/\s+/, "-")          # Convert spaces to hyphens
                   .gsub(/-+/, "-")           # Remove consecutive hyphens
                   .gsub(/\A-|-\z/, "")       # Remove leading/trailing hyphens
  end

  def format_color
    self.color = color.upcase if color
  end
end
