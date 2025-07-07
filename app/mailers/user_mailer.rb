class UserMailer < ApplicationMailer
  default from: ENV.fetch('SMTP_FROM_EMAIL', 'noreply@smartlift.com')

  def reset_password_email(user, token)
    @user = user
    @token = token
    @reset_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/reset-password/#{@token}"
    @expires_at = 30.minutes.from_now

    mail(
      to: @user.email,
      subject: 'SmartLift - Restablecer tu contraseña'
    )
  end

  def password_reset_success(user)
    @user = user

    mail(
      to: @user.email,
      subject: 'SmartLift - Tu contraseña ha sido cambiada'
    )
  end
end