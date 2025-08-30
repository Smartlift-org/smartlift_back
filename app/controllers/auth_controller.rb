class AuthController < ApplicationController
    #POST /auth/login
    skip_before_action :authorize_request

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
            token = encode_token({ user_id: user.id})
            render json: { token: token }, status: :ok
        else
            render json: { error: "Credenciales inválidas" }, status: :unauthorized
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
end