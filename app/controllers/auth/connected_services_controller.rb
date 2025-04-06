class Auth::ConnectedServicesController < ApplicationController
  before_action :ensure_authenticated

  def index
    @connected_services = Current.user.connected_services
  end

  def destroy
    service = Current.user.connected_services.find(params[:id])

    # Prevent deletion of the last authentication method if no password is set
    if Current.user.connected_services.count == 1 && Current.user.password_digest.blank?
      redirect_to auth_connected_services_path, alert: "You cannot remove your last login method. Please set a password first."
      return
    end

    if service.destroy
      redirect_to auth_connected_services_path, notice: "Successfully disconnected #{service.provider.titleize}."
    else
      redirect_to auth_connected_services_path, alert: "Could not disconnect #{service.provider.titleize}."
    end
  end
end
