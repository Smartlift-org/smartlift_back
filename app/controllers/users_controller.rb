class UsersController < ApplicationController
    skip_before_action :authorize_request, only: [ :create ]
    before_action :set_user, only: [ :update ]
    before_action :ensure_admin, only: [ :index_coaches, :index_users, :create_by_admin, :show_coach, :show_user, :update_coach, :update_user, :available_users, :assign_users, :unassign_user, :deactivate_coach ]
    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    # GET /profile
    def profile
      user_data = current_user.as_json(only: [ :id, :first_name, :last_name, :email, :role, :created_at ])
      user_data[:profile_picture_url] = current_user.profile_picture_url_with_fallback
      render json: user_data, status: :ok
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

    # POST /users/profile-picture - Update current user's profile picture
    def update_profile_picture
      if params[:profile_picture].present?
        # Handle file upload with Active Storage
        begin
          current_user.profile_picture.attach(params[:profile_picture])
          
          # Validate file type and size
          if current_user.profile_picture.attached?
            blob = current_user.profile_picture.blob
            
            # Check file type
            unless blob.content_type.in?(%w[image/jpeg image/png image/webp])
              current_user.profile_picture.purge
              return render json: { error: "Tipo de archivo no válido. Solo se permiten JPG, PNG y WebP." }, status: :unprocessable_entity
            end
            
            # Check file size (2MB max)
            if blob.byte_size > 2.megabytes
              current_user.profile_picture.purge
              return render json: { error: "El archivo es muy grande. Máximo 2MB." }, status: :unprocessable_entity
            end
            
            # Generate URL for response
            profile_url = current_user.profile_picture_url_with_fallback
            
            render json: {
              message: "Foto de perfil actualizada exitosamente",
              user: current_user.as_json(only: [:id, :first_name, :last_name, :email, :role]).merge(
                profile_picture_url: profile_url
              )
            }, status: :ok
          else
            render json: { error: "Error al procesar la imagen" }, status: :unprocessable_entity
          end
        rescue => e
          render json: { error: "Error al subir la imagen: #{e.message}" }, status: :internal_server_error
        end
      elsif params[:profile_picture_url].present?
        # Fallback: handle URL-based updates (for backward compatibility)
        if current_user.update(profile_picture_url: params[:profile_picture_url])
          render json: {
            message: "Foto de perfil actualizada exitosamente",
            user: current_user.as_json(only: [:id, :first_name, :last_name, :email, :role, :profile_picture_url])
          }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      else
        render json: { error: "No se proporcionó imagen o URL" }, status: :bad_request
      end
    end

    # GET /users/:id/profile-picture - Get user's profile picture URL
    def get_profile_picture
      user = User.find(params[:id])
      render json: {
        profile_picture_url: user.profile_picture_url_with_fallback,
        user_id: user.id,
        full_name: "#{user.first_name} #{user.last_name}"
      }, status: :ok
    end

    # GET /admin/coaches - Admin only: list all coaches
    def index_coaches
      coaches = User.coach.select(:id, :first_name, :last_name, :email, :profile_picture_url, :created_at)
      render json: coaches, status: :ok
    end

    # GET /admin/users - Admin only: list all basic users
    def index_users
      users = User.user.select(:id, :first_name, :last_name, :email, :profile_picture_url, :created_at)
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

    # GET /admin/coaches/:id - Admin only: get coach details with assigned users
    def show_coach
      coach = User.coach.find(params[:id])
      assigned_users = coach.users.select(:id, :first_name, :last_name, :email, :profile_picture_url, :created_at)
      
      render json: {
        coach: coach.as_json(only: [:id, :first_name, :last_name, :email, :role, :profile_picture_url, :created_at]),
        assigned_users: assigned_users
      }, status: :ok
    end

    # GET /admin/users/:id - Admin only: get user details
    def show_user
      user = User.user.find(params[:id])
      assigned_coach = user.coaches.first
      
      render json: {
        **user.as_json(only: [:id, :first_name, :last_name, :email, :role, :profile_picture_url, :created_at]),
        assigned_coach: assigned_coach&.as_json(only: [:id, :first_name, :last_name, :email, :profile_picture_url])
      }, status: :ok
    end

    # PATCH /admin/coaches/:id - Admin only: update coach information
    def update_coach
      coach = User.coach.find(params[:id])
      
      # Validate that user params are present
      unless params[:user].present?
        return render json: { error: "Datos de usuario requeridos" }, status: :bad_request
      end
      
      # Sanitize email if provided
      if params[:user][:email].present?
        email = sanitize_email(params[:user][:email])
        unless valid_email_format?(email)
          return render json: { error: "Formato de email inválido" }, status: :unprocessable_entity
        end
        params[:user][:email] = email
      end
      
      # Handle password validation
      if params[:user][:password].present?
        if params[:user][:password].length < 6
          return render json: { error: "La contraseña debe tener al menos 6 caracteres" }, status: :unprocessable_entity
        end
        if params[:user][:password] != params[:user][:password_confirmation]
          return render json: { error: "La confirmación de contraseña no coincide" }, status: :unprocessable_entity
        end
      end
      
      if coach.update(admin_update_params)
        render json: coach.as_json(only: [:id, :first_name, :last_name, :email, :role, :created_at]), status: :ok
      else
        render json: { errors: coach.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH /admin/users/:id - Admin only: update user information
    def update_user
      user = User.user.find(params[:id])
      
      # Sanitize email if provided
      if params[:user][:email].present?
        email = sanitize_email(params[:user][:email])
        unless valid_email_format?(email)
          return render json: { error: "Formato de email inválido" }, status: :unprocessable_entity
        end
        params[:user][:email] = email
      end
      
      if user.update(admin_update_params)
        render json: user.as_json(only: [:id, :first_name, :last_name, :email, :role, :created_at]), status: :ok
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # GET /admin/available-users - Admin only: get users without assigned coach
    def available_users
      # Get users that don't have any coach assigned
      available_users = User.user.left_joins(:user_coaches).where(coach_users: { id: nil })
                           .select(:id, :first_name, :last_name, :email, :created_at)
      
      render json: available_users, status: :ok
    end

    # POST /admin/coaches/:id/assign-users - Admin only: assign users to coach
    def assign_users
      coach = User.coach.find(params[:id])
      user_ids = params[:user_ids] || []
      
      if user_ids.empty?
        return render json: { error: "Debe seleccionar al menos un usuario" }, status: :unprocessable_entity
      end
      
      # Validate that all user_ids exist and are users (not coaches or admins)
      users = User.user.where(id: user_ids)
      if users.count != user_ids.count
        return render json: { error: "Algunos usuarios seleccionados no son válidos" }, status: :unprocessable_entity
      end
      
      # Remove users from any existing coach assignments first
      CoachUser.where(user_id: user_ids).destroy_all
      
      # Assign users to the coach
      user_ids.each do |user_id|
        CoachUser.create!(coach_id: coach.id, user_id: user_id)
      end
      
      # Return updated coach details
      assigned_users = coach.users.select(:id, :first_name, :last_name, :email, :created_at)
      render json: {
        message: "Usuarios asignados exitosamente",
        coach: coach.as_json(only: [:id, :first_name, :last_name, :email, :role, :created_at]),
        assigned_users: assigned_users
      }, status: :ok
    end

    # DELETE /admin/coaches/:coach_id/users/:user_id - Admin only: unassign user from coach
    def unassign_user
      coach = User.coach.find(params[:id])
      user = User.user.find(params[:user_id])
      
      coach_user = CoachUser.find_by(coach_id: coach.id, user_id: user.id)
      if coach_user
        coach_user.destroy!
        render json: { message: "Usuario desasignado exitosamente" }, status: :ok
      else
        render json: { error: "El usuario no está asignado a este entrenador" }, status: :not_found
      end
    end

    # DELETE /admin/coaches/:id - Admin only: deactivate/delete coach
    def deactivate_coach
      coach = User.coach.find(params[:id])
      
      # Check if coach has assigned users
      assigned_users_count = coach.users.count
      
      if assigned_users_count > 0
        # Unassign all users from this coach before deactivating
        CoachUser.where(coach_id: coach.id).destroy_all
      end
      
      # Delete the coach (you could also implement soft delete by adding an 'active' field)
      coach.destroy!
      
      render json: {
        message: "Entrenador desactivado exitosamente",
        unassigned_users_count: assigned_users_count
      }, status: :ok
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

    def admin_update_params
      # Admin can update user information including role
      params.require(:user).permit(
        :first_name,
        :last_name,
        :email,
        :password,
        :password_confirmation,
        :role
      )
    end

    def sanitize_email(email)
      # Remove whitespace and convert to lowercase
      email.to_s.strip.downcase
    end

    def valid_email_format?(email)
      # Basic email format validation
      email_regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
      email_regex.match?(email)
    end
end
