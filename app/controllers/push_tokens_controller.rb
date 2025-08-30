class PushTokensController < ApplicationController
  before_action :authenticate_user!
  
  def update
    if current_user.update(push_token_params)
      render json: { message: "Token de notificaciones actualizado correctamente" }, status: :ok
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def destroy
    current_user.update(expo_push_token: nil)
    render json: { message: "Token de notificaciones eliminado" }, status: :ok
  end
  
  def toggle_notifications
    current_user.update(push_notifications_enabled: !current_user.push_notifications_enabled?)
    render json: { 
      message: "Notificaciones #{current_user.push_notifications_enabled? ? 'activadas' : 'desactivadas'}",
      push_notifications_enabled: current_user.push_notifications_enabled?
    }, status: :ok
  end
  
  private
  
  def push_token_params
    params.permit(:expo_push_token, :push_notifications_enabled)
  end
end
