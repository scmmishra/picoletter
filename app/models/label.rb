class Label < ApplicationRecord
  belongs_to :newsletter

  validates :name, presence: true, uniqueness: { scope: :newsletter_id, case_sensitive: false }
  validates :color, presence: true, format: { with: /\A#(?:[0-9a-fA-F]{3}){1,2}\z/, message: "must be a valid hex color code" }
  validates :name, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: "must be in kebab-case format" }
  
  before_validation :format_name
  before_save :format_color
  
  private
  
  def format_name
    return unless name
    # Convert to kebab case
    self.name = name.downcase
                   .gsub(/[^a-z0-9\s-]/, '') # Remove invalid chars
                   .gsub(/\s+/, '-')          # Convert spaces to hyphens
                   .gsub(/-+/, '-')           # Remove consecutive hyphens
                   .gsub(/\A-|-\z/, '')       # Remove leading/trailing hyphens
  end
  
  def format_color
    self.color = color.upcase if color
  end
end
