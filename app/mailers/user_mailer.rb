class UserMailer < ApplicationMailer
  default from: -> { ENV["SMTP_FROM_EMAIL"] || "noreply@smartlift.com" }

  def reset_password_email(user, token)
    @user = user
    @token = token

    # Para desarrollo, simplificamos el uso del token (para aplicación móvil)
    # URL típica para web: "#{ENV['FRONTEND_URL'] || 'http://localhost:3000'}/reset-password/#{@token}"
    @reset_url = "#{ENV['FRONTEND_URL'] || 'http://localhost:3000'}/reset-password/#{@token}"

    # También proporcionamos el token solo para copiar y pegar en aplicaciones móviles
    @reset_token = @token
    @expires_at = 30.minutes.from_now

    mail(
      to: @user.email,
      subject: "SmartLift - Restablecer tu contraseña"
    )
  end

  def password_reset_success(user)
    @user = user

    mail(
      to: @user.email,
      subject: "SmartLift - Tu contraseña ha sido cambiada"
    )
  end
end
