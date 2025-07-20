class UsersController < ApplicationController
    skip_before_action :authorize_request, only: [ :create ]
    before_action :set_user, only: [ :update ]
    before_action :ensure_admin, only: [ :index_coaches, :index_users, :create_by_admin ]
    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    # GET /profile
    def profile
      render json: current_user.as_json(only: [ :id, :first_name, :last_name, :email, :role, :created_at ]), status: :ok
    end

    # POST /users
    def create
      # Sanitize and validate email
      email = sanitize_email(params[:user][:email])

      unless valid_email_format?(email)
        return render json: { error: "Formato de email inválido" }, status: :unprocessable_entity
      end

      # Update the email in the nested params
      params[:user][:email] = email

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

    # GET /admin/coaches - Admin only: list all coaches
    def index_coaches
      coaches = User.coach.select(:id, :first_name, :last_name, :email, :created_at)
      render json: coaches, status: :ok
    end

    # GET /admin/users - Admin only: list all basic users
    def index_users
      users = User.user.select(:id, :first_name, :last_name, :email, :created_at)
      render json: users, status: :ok
    end

    # POST /admin/users - Admin only: create user with specific role
    def create_by_admin
      # Sanitize and validate email
      email = sanitize_email(params[:user][:email])

      unless valid_email_format?(email)
        return render json: { error: "Formato de email inválido" }, status: :unprocessable_entity
      end

      # Update the email in the nested params
      params[:user][:email] = email

      user = User.new(admin_user_params)
      if user.save
        render json: user.as_json(only: [:id, :first_name, :last_name, :email, :role, :created_at]), status: :created
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def update_params
      # Only allow updating specific fields
      params.require(:user).permit(
        :first_name,
        :last_name,
        :email,
        :password,
        :password_confirmation
      )
    end

    def user_params
      # For new user creation, we can allow role assignment
      params.require(:user).permit(
        :first_name,
        :last_name,
        :email,
        :password,
        :password_confirmation,
        :role
      )
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

    def ensure_admin
      unless current_user&.admin?
        render json: { error: "Acceso denegado. Solo administradores." }, status: :forbidden
      end
    end

    def admin_user_params
      # Admin can set any role when creating users
      params.require(:user).permit(
        :first_name,
        :last_name,
        :email,
        :password,
        :password_confirmation,
        :role
      )
    end
end
