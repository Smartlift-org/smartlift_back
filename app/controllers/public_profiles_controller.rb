class PublicProfilesController < ApplicationController
  # Public endpoints - no authentication required
  
  # GET /users/public-profiles
  def index
    # Base query for public profiles
    base_query = User.joins(:user_privacy_setting)
                     .where(user_privacy_settings: { is_profile_public: true })
                     .includes(:user_privacy_setting, :user_stat)

    # Apply search filter if provided
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      base_query = base_query.where(
        "LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(CONCAT(first_name, ' ', last_name)) LIKE ?",
        search_term, search_term, search_term
      )
    end

    # Pagination
    page = params[:page] || 1
    per_page = [params[:per_page]&.to_i || 20, 50].min

    @public_profiles = base_query.page(page).per(per_page)

    # Serialize profiles
    profiles_data = @public_profiles.map do |user|
      profile_data = user.public_profile_data
      next unless profile_data # Skip if profile is somehow not public
      
      # Add basic stats for listing
      profile_data[:stats] = {
        workouts_count: profile_data[:completed_workouts_count] || 0,
        has_personal_records: user.privacy_settings.show_personal_records? && user.get_recent_personal_records(1).any?,
        favorite_exercises_count: profile_data[:favorite_exercises]&.length || 0
      }
      
      profile_data
    end.compact

    render json: {
      success: true,
      data: {
        profiles: profiles_data,
        pagination: {
          current_page: @public_profiles.current_page,
          total_pages: @public_profiles.total_pages,
          total_count: @public_profiles.total_count,
          per_page: @public_profiles.limit_value
        },
        filters_applied: {
          search: params[:search]
        }
      }
    }
  end

  # GET /users/:id/public-profile
  def show
    @user = User.find(params[:id])
    
    unless @user.profile_is_public?
      render json: {
        success: false,
        error: "Este perfil no es público"
      }, status: :not_found
      return
    end

    profile_data = @user.public_profile_data
    
    render json: {
      success: true,
      data: {
        profile: profile_data
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: "Usuario no encontrado"
    }, status: :not_found
  end
end
