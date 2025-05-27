class UsersController < ApplicationController
    skip_before_action :authorize_request, only: [:create]
    before_action :set_user, only: [:update]
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    
    # GET /profile
    def profile
      render json: current_user, status: :ok
    end
  
    # POST /users
    def create
      # Sanitize and validate email
      email = sanitize_email(params[:email])
      
      unless valid_email_format?(email)
        return render json: { error: "Formato de email inválido" }, status: :unprocessable_entity
      end

      params[:email] = email
      
      user = User.new(user_params)
      if user.save
        render json: user, status: :created
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH /users/:id
    def update
      if @user.update(update_params)
        render json: @user, status: :ok
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private
  
    def set_user
      @user = User.find(params[:id])
    end

    def update_params
      params.except(:id, :user, :controller, :action)
            .permit(:first_name, :last_name, :email, :password, :password_confirmation)
    end

    def user_params
      params.permit(:first_name, :last_name, :email, :password, :password_confirmation)
    end

    def valid_email_format?(email)
      return false if email.blank?
      email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
    end

    def sanitize_email(email)
      return nil if email.blank?
      email.strip.downcase
    end

    def not_found
      render json: { error: "Usuario no encontrado" }, status: :not_found
    end
end