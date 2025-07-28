class ApplicationController < ActionController::Base
  before_action :authorize_request

  private

  def encode_token(payload)
    JWT.encode(payload, Rails.application.secret_key_base)
  end

  def decode_token
    auth_header = request.headers["Authorization"]
    token = auth_header.split.last if auth_header
    begin
      JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256")
    rescue JWT::DecodeError
      nil
    end
  end

  def current_user
    if decode_token
      user_id = decode_token[0]["user_id"]
      @current_user ||= User.find_by(id: user_id)
    end
  end

  # API Key authentication for external agents (AI, integrations)
  def authenticate_api_key
    api_key = request.headers['X-API-Key']
    valid_api_keys = Rails.application.credentials.api_keys || []
    
    return true if valid_api_keys.include?(api_key)
    
    render json: { error: "Invalid API Key" }, status: :unauthorized
    false
  end

  # Flexible authorization that accepts either JWT or API Key
  def authorize_request_or_api_key
    return if authenticate_api_key
    authorize_request
  end

  def authorize_request
    render json: { error: "No Autorizado" }, status: :unauthorized unless current_user
  end

  # Role-based authorization methods
  def ensure_admin
    render json: { error: "Acceso denegado. Se requiere rol de administrador." }, status: :forbidden unless current_user&.admin?
  end

  def ensure_coach_or_admin
    render json: { error: "Acceso denegado. Se requiere rol de entrenador o administrador." }, status: :forbidden unless current_user&.coach? || current_user&.admin?
  end

  def ensure_user_or_coach_or_admin
    render json: { error: "Acceso denegado. Se requiere cuenta de usuario." }, status: :forbidden unless current_user&.user? || current_user&.coach? || current_user&.admin?
  end

  # Alias para compatibilidad con Devise y tests
  alias_method :authenticate_user!, :authorize_request
end
