module PublicHostResolver
  extend ActiveSupport::Concern

  included do
    before_action :resolve_public_newsletter
    helper_method :current_public_newsletter,
                  :current_publishing_domain,
                  :hosted_public_request?,
                  :public_newsletter_path,
                  :public_newsletter_url,
                  :public_newsletter_all_posts_path,
                  :public_newsletter_post_path,
                  :public_subscribe_path,
                  :public_embed_subscribe_path,
                  :public_unsubscribe_path,
                  :public_confirm_path,
                  :public_almost_there_path
  end

  private

  attr_reader :current_publishing_domain, :platform_host_slug

  def resolve_public_newsletter
    @current_publishing_domain = find_active_publishing_domain
    @platform_host_slug = nil
    slug = params[:slug].presence

    unless slug
      @platform_host_slug = slug_from_platform_host
      slug = @platform_host_slug if slug.blank?
    end

    @newsletter = resolve_newsletter(slug)

    if @newsletter
      params[:slug] = slug.presence || @newsletter.slug
    else
      head :not_found
    end
  end

  def resolve_newsletter(slug)
    return @current_publishing_domain.newsletter if @current_publishing_domain

    return if slug.blank?

    Newsletter.from_slug(slug)
  end

  def find_active_publishing_domain
    host = request.host&.downcase
    return if host.blank?

    PublishingDomain.active.find_by(hostname: host)
  end

  def slug_from_platform_host
    host = request.host&.downcase
    base = AppConfig.platform_publishing_domain&.downcase

    return if host.blank? || base.blank? || host == base

    suffix = ".#{base}"
    return unless host.end_with?(suffix)

    slug = host.delete_suffix(suffix)
    slug.presence
  end

  def current_public_newsletter
    @newsletter
  end

  def hosted_public_request?
    current_publishing_domain.present? || platform_host_slug.present?
  end

  def public_newsletter_path(**options)
    if hosted_public_request?
      hosted_public_newsletter_path(**options)
    else
      newsletter_path(@newsletter.slug, **options)
    end
  end

  def public_newsletter_url(**options)
    if hosted_public_request?
      hosted_public_newsletter_url(**options)
    else
      newsletter_url(@newsletter.slug, **options)
    end
  end

  def public_newsletter_all_posts_path(**options)
    if hosted_public_request?
      hosted_public_newsletter_all_posts_path(**options)
    else
      newsletter_all_posts_path(@newsletter.slug, **options)
    end
  end

  def public_newsletter_post_path(post_slug:, **options)
    if hosted_public_request?
      hosted_public_newsletter_post_path(post_slug, **options)
    else
      newsletter_post_path(@newsletter.slug, post_slug, **options)
    end
  end

  def public_subscribe_path(**options)
    if hosted_public_request?
      hosted_public_subscribe_path(**options)
    else
      subscribe_path(@newsletter.slug, **options)
    end
  end

  def public_embed_subscribe_path(**options)
    if hosted_public_request?
      hosted_public_embed_subscribe_path(**options)
    else
      embed_subscribe_path(@newsletter.slug, **options)
    end
  end

  def public_unsubscribe_path(**options)
    if hosted_public_request?
      hosted_public_unsubscribe_path(**options)
    else
      unsubscribe_path(@newsletter.slug, **options)
    end
  end

  def public_confirm_path(**options)
    if hosted_public_request?
      hosted_public_confirm_path(**options)
    else
      confirm_path(@newsletter.slug, **options)
    end
  end

  def public_almost_there_path(**options)
    if hosted_public_request?
      hosted_public_almost_there_path(**options)
    else
      almost_there_path(@newsletter.slug, **options)
    end
  end
end
