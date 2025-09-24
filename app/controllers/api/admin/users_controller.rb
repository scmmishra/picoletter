class Api::Admin::UsersController < Api::Admin::BaseController
  before_action :set_user

  def update_limits
    if @user.update(limits_params)
      render json: {
        success: true,
        user: {
          id: @user.id,
          email: @user.email,
          limits: @user.limits,
          additional_data: @user.additional_data
        }
      }
    else
      render json: { success: false, errors: @user.errors.full_messages }, status: :unprocessable_content
    end
  end

  def toggle_active
    active = params[:active].to_s.downcase == "true"

    if @user.update(active: active)
      render json: {
        success: true,
        user: {
          id: @user.id,
          email: @user.email,
          active: @user.active
        }
      }
    else
      render json: { success: false, errors: @user.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def set_user
    @user = User.find_by(id: params[:id])

    unless @user
      render json: { success: false, error: "User not found" }, status: :not_found
    end
  end

  def limits_params
    permitted_params = params.permit(
      limits: [ :subscriber_limit, :monthly_email_limit ],
      additional_data: {}
    )

    # Convert string keys to symbols if needed
    if params[:limits].is_a?(Hash)
      permitted_params[:limits] ||= {}
      permitted_params[:limits][:subscriber_limit] = params[:limits][:subscriber_limit].to_i if params[:limits][:subscriber_limit].present?
      permitted_params[:limits][:monthly_email_limit] = params[:limits][:monthly_email_limit].to_i if params[:limits][:monthly_email_limit].present?
    end

    if params[:additional_data].is_a?(Hash)
      permitted_params[:additional_data] = params[:additional_data]
    end

    permitted_params
  end
end
