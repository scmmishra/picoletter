class Public::BaseController < ApplicationController
  before_action :resolve_public_newsletter

  helper_method :current_public_newsletter, :current_publishing_domain

  private

  attr_reader :current_publishing_domain

  def resolve_public_newsletter
    @current_publishing_domain = find_active_publishing_domain
    slug = params[:slug].presence

    unless slug
      slug = slug_from_platform_host
    end

    @newsletter = resolve_newsletter(slug)

    if @newsletter.present?
      params[:slug] = slug.presence || @newsletter.slug
    else
      head :not_found
    end
  end

  def resolve_newsletter(slug)
    return current_publishing_domain.newsletter if current_publishing_domain

    return if slug.blank?

    Newsletter.from_slug(slug)
  end

  def find_active_publishing_domain
    host = request.host&.downcase
    return if host.blank?

    PublishingDomain.active.includes(:newsletter).find_by(hostname: host)
  end

  def slug_from_platform_host
    host = request.host&.downcase
    platform_domain = AppConfig.platform_publishing_domain&.downcase

    return if host.blank? || platform_domain.blank?
    return if host == platform_domain

    suffix = ".#{platform_domain}"
    return unless host.end_with?(suffix)

    slug = host.delete_suffix(suffix)
    slug.presence
  end

  def current_public_newsletter
    @newsletter
  end
end
