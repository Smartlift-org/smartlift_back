class ApplicationController < ActionController::Base
  before_action :authorize_request

  private

  def encode_token(payload)
    JWT.encode(payload, Rails.application.secret_key_base)
  end

  def decode_token
    auth_header = request.headers['Authorization']
    token = auth_header.split.last if auth_header
    begin
      JWT.decode( token, Rails.application.secret_key_base, true, algorithm: 'HS256')
    rescue JWT::DecodeError
      nil
    end
  end

  def current_user
    if decode_token
      user_id = decode_token[0]['user_id']
      @current_user ||= User.find_by(id: user_id)
    end
  end

  def authorize_request
    render json: { error: "No Autorizado" }, status: :unauthorized unless current_user
  end
end
