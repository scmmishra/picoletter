class Api::Admin::UsersController < Api::BaseController
  before_action :set_user, only: [:show, :update]

  def index
    @users = User.all
    render json: @users.as_json(only: [:id, :email, :name, :active, :created_at, :updated_at], 
                                methods: [:subscriber_limit, :monthly_email_limit])
  end

  def show
    render json: @user.as_json(only: [:id, :email, :name, :active, :created_at, :updated_at], 
                               methods: [:subscriber_limit, :monthly_email_limit],
                               include: {
                                 additional_data: {},
                                 limits: {}
                               })
  end

  def update
    if @user.update(user_params)
      render json: @user.as_json(only: [:id, :email, :name, :active, :created_at, :updated_at], 
                                 methods: [:subscriber_limit, :monthly_email_limit],
                                 include: {
                                   additional_data: {},
                                   limits: {}
                                 })
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  def user_params
    params.require(:user).permit(
      :active,
      additional_data: {},
      limits: [:subscriber_limit, :monthly_email_limit]
    )
  end
end
