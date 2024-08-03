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
    excluded_candidates =  %w[new edit create update destroy show index app dev admin auth login logout sign_in sign_out sign_up home about contact privacy terms faq help search api feed rss xml json sitemap settings profile account dashboard blog news articles posts get post put patch delete options head html htm php asp aspx js css png jpg gif pdf healthz]
    slug_candidate = counter.zero? ? base_slug : "#{base_slug}-#{counter}"
    return generate_unique_slug(base_slug, counter + 1) if excluded_candidates.include?(slug_candidate)
    return generate_unique_slug(base_slug, counter + 1) if self.class.exists?(slug: slug_candidate)

    slug_candidate
  end
end
