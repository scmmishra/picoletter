# Sluggable is a concern that handles generating a unique slug from another attribute and validating its presence and uniqueness.
#
# It adds a before_validation callback to generate the slug, and validations on the slug attribute.
# It also adds class methods to find records by slug, set the slug column and uniqueness scope, etc.
#
# When included, it will generate the slug before validation based on the configured slug column,
# retrying with an incrementing counter suffix if needed for uniqueness.
module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_slug
    validates :slug, presence: true, uniqueness: { scope: slug_uniqueness_scope }
  end

  class_methods do
    attr_reader :slug_uniqueness_scope, :slug_column

    def from_slug(slug)
      find_by(slug: slug.downcase)
    end

    private

    def sluggable_on(column, scope: nil)
      @slug_column = column
      @slug_uniqueness_scope = scope
    end
  end

  private

  def generate_slug
    return if slug.present?

    value = send(self.class.slug_column)

    base_slug = value.present? ? value.parameterize : SecureRandom.uuid
    self.slug = generate_unique_slug(base_slug)
  end

  def generate_unique_slug(base_slug, counter = 0)
    slug_candidate = counter.zero? ? base_slug : "#{base_slug}-#{counter}"
    return slug_candidate unless self.class.exists?(slug: slug_candidate)

    generate_unique_slug(base_slug, counter + 1)
  end
end
