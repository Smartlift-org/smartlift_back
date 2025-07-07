class AuthController < ApplicationController
    # POST /auth/login, /auth/forgot-password, /auth/reset-password
    skip_before_action :authorize_request

    # Rate limiting for password recovery endpoints
    before_action :check_password_reset_rate_limit, only: [:forgot_password, :reset_password]

    def login
        # sanitize email and valid email
        email = sanitize_email(params[:email])

        unless valid_email_format?(email)
            return render json: { error: "Formato de email inválido" }, status: :unprocessable_entity
        end

        if email.blank? || params[:password].blank?
            return render json: { error: "Email y password son requeridos" }, status: :unprocessable_entity
        end

        user = User.find_by(email: email)

        if user&.authenticate(params[:password])
            token = encode_token({ user_id: user.id })
            render json: { token: token }, status: :ok
        else
            render json: { error: "Credenciales inválidas" }, status: :unauthorized
        end
    end

    # POST /auth/forgot-password
    def forgot_password
        email = sanitize_email(params[:email])

        unless valid_email_format?(email)
            Rails.logger.warn "[PASSWORD_RECOVERY] Invalid email format attempted: #{params[:email]} from IP: #{request.remote_ip}"
            return render json: { error: "Formato de email inválido" }, status: :unprocessable_entity
        end

        user = User.find_by(email: email)
        
        if user
            Rails.logger.info "[PASSWORD_RECOVERY] Valid reset request for user_id: #{user.id}, email: #{email}"
            
            # Generate password reset token
            token = generate_password_reset_token(user)
            
            # Send password reset email
            begin
                UserMailer.reset_password_email(user, token).deliver_now
                Rails.logger.info "[PASSWORD_RECOVERY] Reset email sent successfully to user_id: #{user.id}"
                render json: { 
                    message: "Si el email existe en nuestro sistema, recibirás instrucciones para restablecer tu contraseña.",
                    email: email 
                }, status: :ok
            rescue => e
                Rails.logger.error "[PASSWORD_RECOVERY] Failed to send email to user_id: #{user.id}, error: #{e.message}"
                render json: { error: "Error al enviar el email. Intenta nuevamente." }, status: :internal_server_error
            end
        else
            Rails.logger.warn "[PASSWORD_RECOVERY] Reset attempt for non-existent email: #{email} from IP: #{request.remote_ip}"
            # Return success message even if user doesn't exist (security best practice)
            render json: { 
                message: "Si el email existe en nuestro sistema, recibirás instrucciones para restablecer tu contraseña.",
                email: email 
            }, status: :ok
        end
    end

    # POST /auth/reset-password
    def reset_password
        token = params[:token]
        new_password = params[:password]
        password_confirmation = params[:password_confirmation]

        # Validate required parameters
        if token.blank? || new_password.blank?
            return render json: { error: "Token y nueva contraseña son requeridos" }, status: :unprocessable_entity
        end

        # Validate password confirmation
        if new_password != password_confirmation
            return render json: { error: "La confirmación de contraseña no coincide" }, status: :unprocessable_entity
        end

        # Validate password strength
        unless valid_password?(new_password)
            return render json: { 
                error: "La contraseña debe tener al menos 6 caracteres",
                requirements: "Mínimo 6 caracteres"
            }, status: :unprocessable_entity
        end

        # Find user by token and check expiration
        user = find_user_by_reset_token(token)
        
        if user.nil?
            return render json: { error: "Token inválido o expirado" }, status: :unprocessable_entity
        end

        # Update password
        begin
            user.update!(
                password: new_password,
                password_confirmation: password_confirmation,
                password_reset_token: nil,
                password_reset_sent_at: nil
            )

            # Send confirmation email
            UserMailer.password_reset_success(user).deliver_now

            render json: { 
                message: "Tu contraseña ha sido actualizada exitosamente",
                user: {
                    id: user.id,
                    email: user.email,
                    name: "#{user.first_name} #{user.last_name}"
                }
            }, status: :ok

        rescue ActiveRecord::RecordInvalid => e
            render json: { 
                error: "Error al actualizar la contraseña",
                details: e.record.errors.full_messages
            }, status: :unprocessable_entity
        rescue => e
            Rails.logger.error "Failed to reset password: #{e.message}"
            render json: { error: "Error interno del servidor" }, status: :internal_server_error
        end
    end

    private

    def valid_email_format?(email)
        return false if email.blank?
        email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
    end

    def sanitize_email(email)
        return nil if email.blank?
        email.strip.downcase
    end

    def valid_password?(password)
        password.present? && password.length >= 6
    end

    def generate_password_reset_token(user)
        # Generate secure random token
        token = SecureRandom.urlsafe_base64(32)
        
        # Store token and timestamp in user record
        user.update!(
            password_reset_token: Digest::SHA256.hexdigest(token),
            password_reset_sent_at: Time.current
        )
        
        # Return the original token (not hashed) for email
        token
    end

    def find_user_by_reset_token(token)
        return nil if token.blank?
        
        # Hash the provided token to compare with stored hash
        hashed_token = Digest::SHA256.hexdigest(token)
        
        # Find user and check token expiration (30 minutes)
        user = User.find_by(password_reset_token: hashed_token)
        
        if user && user.password_reset_sent_at && user.password_reset_sent_at > 30.minutes.ago
            user
        else
            nil
        end
    end

    # Rate limiting for password recovery to prevent abuse
    def check_password_reset_rate_limit
        client_ip = request.remote_ip
        cache_key = "password_reset_attempts:#{client_ip}"
        
        # Get current attempt count (max 5 attempts per hour)
        attempt_count = Rails.cache.read(cache_key) || 0
        
        if attempt_count >= 5
            render json: { 
                error: "Demasiados intentos de recuperación de contraseña. Intenta nuevamente en una hora.",
                retry_after: 3600
            }, status: :too_many_requests
            return false
        end
        
        # Increment attempt count with 1 hour expiration
        Rails.cache.write(cache_key, attempt_count + 1, expires_in: 1.hour)
        true
    end
end
