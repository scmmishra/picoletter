class Api::V1::SubscribersController < Api::V1::BaseController
  DEFAULT_PER_PAGE = 30
  MAX_PER_PAGE = 100

  before_action :check_permission!
  before_action :set_subscriber, only: [ :show, :update, :destroy ]

  rate_limit to: 30, within: 1.minute, by: -> { @api_token&.id || request.remote_ip }

  def index
    subscribers = filtered_subscribers
    return if performed?

    page = page_param
    per_page = per_page_param
    total = subscribers.count
    paginated_subscribers = subscribers.offset((page - 1) * per_page).limit(per_page)

    render json: {
      data: paginated_subscribers.map { |subscriber| serialize_subscriber(subscriber) },
      meta: {
        page: page,
        per_page: per_page,
        total: total,
        total_pages: (total.to_f / per_page).ceil
      }
    }
  end

  def create
    email = params[:email]
    name = params[:name]
    labels = params[:labels]

    unless email.present?
      render json: { error: "Email is required" }, status: :unprocessable_entity
      return
    end

    result = CreateSubscriberJob.perform_now(@newsletter.id, email, name, labels, "api", {})

    if result
      render json: { message: "Subscriber created", email: email }, status: :created
    else
      render json: { error: "Invalid email address" }, status: :unprocessable_entity
    end
  end

  def show
    render json: { data: serialize_subscriber(@subscriber) }
  end

  def lookup
    email = params[:email].to_s.strip
    if email.blank?
      render json: { error: "Email is required" }, status: :unprocessable_entity
      return
    end

    subscriber = @newsletter.subscribers
      .where("LOWER(email) = ?", email.downcase)
      .first

    unless subscriber
      render json: { error: "Subscriber not found" }, status: :not_found
      return
    end

    render json: { data: serialize_subscriber(subscriber) }
  end

  def update
    attributes = subscriber_params.to_h
    if attributes.empty?
      render json: { error: "At least one field is required" }, status: :unprocessable_entity
      return
    end

    if @subscriber.update(attributes)
      render json: { data: serialize_subscriber(@subscriber) }
    else
      render json: { error: @subscriber.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def destroy
    @subscriber.destroy!
    head :no_content
  end

  def counts
    counts = Rails.cache.fetch("newsletter/#{@newsletter.id}/subscriber_counts") do
      subscribers = @newsletter.subscribers
      {
        total: subscribers.count,
        verified: subscribers.verified.count,
        unverified: subscribers.unverified.count,
        unsubscribed: subscribers.unsubscribed.count
      }
    end

    render json: counts
  end

  private

  def check_permission!
    unless @api_token.has_permission?("subscription")
      render json: { error: "Insufficient permissions" }, status: :forbidden
    end
  end

  def filtered_subscribers
    subscribers = @newsletter.subscribers.order(created_at: :desc)

    status = params[:status].to_s.strip
    if status.present?
      unless Subscriber.statuses.key?(status)
        render json: { error: "Invalid status" }, status: :unprocessable_entity
        return
      end
      subscribers = subscribers.where(status: status)
    end

    label = params[:label].to_s.strip.downcase
    subscribers = subscribers.where("? = ANY(labels)", label) if label.present?

    subscribers
  end

  def set_subscriber
    @subscriber = @newsletter.subscribers.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Subscriber not found" }, status: :not_found
  end

  def subscriber_params
    params.permit(:full_name, :notes, labels: [])
  end

  def page_param
    value = params[:page].to_i
    value.positive? ? value : 1
  end

  def per_page_param
    value = params[:per_page].to_i
    value = DEFAULT_PER_PAGE unless value.positive?
    [ value, MAX_PER_PAGE ].min
  end

  def serialize_subscriber(subscriber)
    {
      id: subscriber.id,
      email: subscriber.email,
      full_name: subscriber.full_name,
      notes: subscriber.notes,
      labels: subscriber.labels || [],
      status: subscriber.status,
      created_via: subscriber.created_via,
      verified_at: subscriber.verified_at,
      unsubscribed_at: subscriber.unsubscribed_at,
      created_at: subscriber.created_at,
      updated_at: subscriber.updated_at
    }
  end
end
