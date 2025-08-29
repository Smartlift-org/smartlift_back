class Api::V1::ChallengesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_challenge, only: [:show, :leaderboard, :destroy]
  before_action :ensure_coach, only: [:create, :destroy, :my_challenges]

  # GET /api/v1/challenges - Desafíos disponibles para el usuario
  def index
    begin
      if @current_user.coach?
        # Entrenadores ven sus propios desafíos
        challenges = @current_user.challenges.current_week.active
                            .includes(challenge_exercises: :exercise)
                            .order(created_at: :desc)

        challenges_with_stats = challenges.map do |challenge|
          challenge_data = challenge.as_json(include: { challenge_exercises: { include: :exercise } })
          challenge_data['participants_count'] = challenge.participants_count
          challenge_data['completed_attempts'] = challenge.completed_attempts
          challenge_data['total_attempts'] = challenge.total_attempts
          challenge_data['is_active_now'] = challenge.is_active_now?
          challenge_data
        end

        render json: challenges_with_stats
      else
        # Usuarios ven desafíos de su entrenador
        coach = @current_user.coaches.first
        return render json: { error: "No tienes un entrenador asignado" }, status: :not_found unless coach

        challenges = coach.challenges.where(is_active: true)
                                  .includes(challenge_exercises: :exercise)
                                  .where('end_date > ?', Time.current)
                                  .order(created_at: :desc)

        challenges_with_stats = challenges.map do |challenge|
          challenge_data = challenge.as_json(include: { challenge_exercises: { include: :exercise } })
          challenge_data['participants_count'] = challenge.participants_count
          challenge_data['completed_attempts'] = challenge.completed_attempts
          challenge_data['total_attempts'] = challenge.total_attempts
          challenge_data['is_active_now'] = challenge.is_active_now?
          challenge_data
        end

        render json: challenges_with_stats

      end

    rescue => e
      Rails.logger.error "Error in challenges#index: #{e.message}"
      render json: { error: "Error al obtener desafíos" }, status: :internal_server_error
    end
  end

  # GET /api/v1/challenges/available - Desafíos disponibles para el usuario
  def available
    begin
      coach = @current_user.coaches.first
      return render json: { error: "No tienes un entrenador asignado" }, status: :not_found unless coach

      challenges = coach.challenges.where(is_active: true)
                                  .includes(challenge_exercises: :exercise)
                                  .where('end_date > ?', Time.current)
                                  .order(created_at: :desc)

      challenges_with_stats = challenges.map do |challenge|
        challenge_data = challenge.as_json(include: { challenge_exercises: { include: :exercise } })
        challenge_data['participants_count'] = challenge.participants_count
        challenge_data['completed_attempts'] = challenge.completed_attempts
        challenge_data['total_attempts'] = challenge.total_attempts
        challenge_data['is_active_now'] = challenge.is_active_now?
        challenge_data
      end

      render json: challenges_with_stats

    rescue => e
      Rails.logger.error "Error in challenges#available: #{e.message}"
      render json: { error: "Error al obtener desafíos disponibles" }, status: :internal_server_error
    end
  end

  # GET /api/v1/challenges/my_challenges - Desafíos creados por el entrenador
  def my_challenges
    begin
      challenges = @current_user.challenges.includes(challenge_exercises: :exercise)
                              .order(created_at: :desc)

      render json: challenges, include: { challenge_exercises: { include: :exercise } }

    rescue => e
      Rails.logger.error "Error in challenges#my_challenges: #{e.message}"
      render json: { error: "Error al obtener mis desafíos" }, status: :internal_server_error
    end
  end

  # GET /api/v1/challenges/:id
  def show
    begin
      challenge_data = @challenge.as_json(include: { challenge_exercises: { include: :exercise } })
      
      # Add computed fields
      challenge_data['participants_count'] = @challenge.participants_count
      challenge_data['total_attempts'] = @challenge.total_attempts
      challenge_data['completed_attempts'] = @challenge.completed_attempts
      challenge_data['is_active_now'] = @challenge.is_active_now?
      
      render json: challenge_data

    rescue => e
      Rails.logger.error "Error in challenges#show: #{e.message}"
      render json: { error: "Error al obtener el desafío" }, status: :internal_server_error
    end
  end

  # POST /api/v1/challenges
  def create
    begin
      challenge = @current_user.challenges.build(challenge_params)
      
      if challenge.save
        render json: challenge, status: :created
      else
        render json: { errors: challenge.errors.full_messages }, status: :unprocessable_entity
      end

    rescue => e
      Rails.logger.error "Error in challenges#create: #{e.message}"
      render json: { error: "Error al crear el desafío" }, status: :internal_server_error
    end
  end

  # GET /api/v1/challenges/:id/leaderboard
  def leaderboard
    begin
      leaderboard_data = @challenge.leaderboard.map.with_index(1) do |attempt, position|
        {
          position: position,
          user: UserBasicSerializer.new(attempt.user),
          completion_time: attempt.completion_time_seconds,
          completed_at: attempt.completed_at,
          formatted_time: attempt.formatted_completion_time
        }
      end

      user_best_attempt = @challenge.user_best_attempt(@current_user)

      render json: {
        success: true,
        data: {
          challenge: @challenge,
          leaderboard: leaderboard_data,
          user_best_attempt: user_best_attempt,
          total_participants: @challenge.participants_count,
          total_completed: @challenge.completed_attempts
        }
      }

    rescue => e
      Rails.logger.error "Error in challenges#leaderboard: #{e.message}"
      render json: {
        success: false,
        message: "Error al obtener el ranking"
      }, status: :internal_server_error
    end
  end

  # DELETE /api/v1/challenges/:id
  def destroy
    begin
      if @challenge.coach != @current_user
        return render json: { error: "No tienes permisos para eliminar este desafío" }, status: :forbidden
      end

      @challenge.destroy
      head :no_content

    rescue => e
      Rails.logger.error "Error in challenges#destroy: #{e.message}"
      render json: { error: "Error al eliminar el desafío" }, status: :internal_server_error
    end
  end

  private

  def set_challenge
    @challenge = Challenge.includes(challenge_exercises: :exercise).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Desafío no encontrado" }, status: :not_found
  end

  def challenge_params
    params.require(:challenge).permit(
      :name, :description, :difficulty_level, :start_date, :end_date, :estimated_duration_minutes,
      challenge_exercises_attributes: [:exercise_id, :sets, :reps, :rest_time_seconds, :order_index, :notes, :_destroy]
    )
  end

  def ensure_coach
    unless @current_user.coach?
      render json: {
        success: false,
        message: "Solo los entrenadores pueden realizar esta acción"
      }, status: :forbidden
    end
  end
end
