module AuthenticationHelper
  def authenticate_user(user)
    token = JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
    request.headers['Authorization'] = "Bearer #{token}"
  end
end 