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
      render json: { success: false, errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def toggle_active
    active = params[:active].to_s.downcase == 'true'
    
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
      render json: { success: false, errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find_by(email: params[:email])
    
    unless @user
      render json: { success: false, error: 'User not found' }, status: :not_found
    end
  end

  def limits_params
    params.permit(
      additional_data: {},
      limits: [:subscriber_limit, :monthly_email_limit]
    )
  end
end
