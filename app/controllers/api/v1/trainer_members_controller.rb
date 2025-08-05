class Api::V1::TrainerMembersController < ApplicationController
  before_action :authorize_request
  before_action :ensure_trainer_role
  before_action :set_trainer

  # GET /api/v1/trainers/:trainer_id/members/:id
  def show
    begin
      @member = @trainer.users.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      return render json: { error: "Miembro no encontrado o no está asignado a este entrenador" }, status: :not_found
    end

    # Devolver solo información básica del miembro
    render json: {
      id: @member.id,
      first_name: @member.first_name,
      last_name: @member.last_name,
      email: @member.email
    }
  end

  # GET /api/v1/trainers/:trainer_id/members/:id/routines
  def routines
    begin
      @member = @trainer.users.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      return render json: { error: "Miembro no encontrado o no está asignado a este entrenador" }, status: :not_found
    end

    @routines = @member.routines.includes(:routine_exercises)

    page = params[:page] || 1
    per_page = [ params[:per_page]&.to_i || 10, 50 ].min

    paginated_routines = @routines.page(page).per(per_page)

    routines_data = paginated_routines.map do |routine|
      {
        id: routine.id,
        name: routine.name,
        description: routine.description,
        difficulty: routine.difficulty,
        created_at: routine.created_at,
        updated_at: routine.updated_at,
        routine_exercises: routine.routine_exercises.map do |routine_exercise|
          {
            id: routine_exercise.id,
            name: routine_exercise.exercise.name,
            primary_muscles: routine_exercise.exercise.primary_muscles,
            level: routine_exercise.exercise.level,
            sets: routine_exercise.sets,
            reps: routine_exercise.reps,
            rest_time: routine_exercise.rest_time,
            weight: routine_exercise.weight
          }
        end
      }
    end

    render json: {
      routines: routines_data,
      pagination: {
        current_page: paginated_routines.current_page,
        total_pages: paginated_routines.total_pages,
        total_count: paginated_routines.total_count,
        per_page: paginated_routines.limit_value
      }
    }
  end

  private

  def set_trainer
    @trainer = User.find_by(id: params[:trainer_id])

    if @trainer.nil?
      render json: { error: "Trainer not found" }, status: :not_found
      return
    end

    authorize_trainer_access!(@trainer.id)
  end

  def ensure_trainer_role
    unless current_user&.coach?
      render json: { error: "Acceso denegado. Se requiere rol de entrenador." },
                    status: :forbidden
    end
  end

  def authorize_trainer_access!(trainer_id)
    unless current_user.id == trainer_id.to_i
      render json: { error: "No tienes permisos para acceder a los datos de este entrenador." },
             status: :forbidden and return
    end
  end

  def calculate_member_consistency(member)
    weeks_with_workouts = 0
    8.times do |i|
      week_start = i.weeks.ago.beginning_of_week
      week_end = i.weeks.ago.end_of_week

      if member.workouts.where(created_at: week_start..week_end).exists?
        weeks_with_workouts += 1
      end
    end

    ((weeks_with_workouts.to_f / 8) * 100).round(1)
  end
end
