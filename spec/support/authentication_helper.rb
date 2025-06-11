module AuthenticationHelper
  def authenticate_user(user)
    # JWT authentication
    token = JWT.encode({ user_id: user.id }, Rails.application.secret_key_base)
    request.headers['Authorization'] = "Bearer #{token}"
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :controller
end
