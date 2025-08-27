class Api::V1::ChallengeAttemptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_challenge
  before_action :set_attempt, only: [:show, :update, :complete]
  before_action :validate_user_access, only: [:create]

  # GET /api/v1/challenges/:challenge_id/attempts - Historial de intentos del usuario
  def index
    begin
      attempts = @challenge.challenge_attempts.where(user: @current_user)
                          .includes(:user, :challenge)
                          .order(created_at: :desc)

      render json: {
        success: true,
        data: attempts
      }, each_serializer: ChallengeAttemptSerializer

    rescue => e
      Rails.logger.error "Error in challenge_attempts#index: #{e.message}"
      render json: {
        success: false,
        message: "Error al obtener el historial de intentos"
      }, status: :internal_server_error
    end
  end

  # GET /api/v1/challenges/:challenge_id/attempts/:id - Detalle de un intento específico
  def show
    begin
      render json: {
        success: true,
        data: ChallengeAttemptSerializer.new(@attempt)
      }

    rescue => e
      Rails.logger.error "Error in challenge_attempts#show: #{e.message}"
      render json: {
        success: false,
        message: "Error al obtener el intento"
      }, status: :internal_server_error
    end
  end

  # POST /api/v1/challenges/:challenge_id/attempts - Iniciar intento
  def create
    begin
      # Verificar que no haya un intento activo
      active_attempt = @challenge.challenge_attempts.where(user: @current_user, status: 'in_progress').first
      if active_attempt
        return render json: {
          success: false,
          message: "Ya tienes un intento activo para este desafío",
          data: { active_attempt_id: active_attempt.id }
        }, status: :conflict
      end

      attempt = @challenge.challenge_attempts.build(
        user: @current_user,
        started_at: Time.current,
        status: 'in_progress'
      )
      
      if attempt.save
        render json: {
          success: true,
          data: ChallengeAttemptSerializer.new(attempt),
          message: "Intento iniciado exitosamente"
        }, status: :created
      else
        render json: {
          success: false,
          errors: attempt.errors.full_messages
        }, status: :unprocessable_entity
      end

    rescue => e
      Rails.logger.error "Error in challenge_attempts#create: #{e.message}"
      render json: {
        success: false,
        message: "Error al iniciar el intento"
      }, status: :internal_server_error
    end
  end

  # PUT /api/v1/challenges/:challenge_id/attempts/:id/complete - Completar intento
  def complete
    begin
      unless @attempt.in_progress?
        return render json: {
          success: false,
          message: "Este intento ya ha sido completado o abandonado"
        }, status: :unprocessable_entity
      end

      completion_time = params[:completion_time_seconds].to_i
      exercise_times = params[:exercise_times] || {}

      # Validar tiempo de completion
      if completion_time <= 0
        return render json: {
          success: false,
          message: "El tiempo de completación debe ser mayor a 0"
        }, status: :unprocessable_entity
      end

      if @attempt.update(
        status: 'completed',
        completed_at: Time.current,
        completion_time_seconds: completion_time,
        exercise_times: exercise_times
      )
        # Obtener posición en el ranking
        position = @challenge.leaderboard
                           .where('completion_time_seconds <= ?', completion_time)
                           .count

        render json: {
          success: true,
          data: ChallengeAttemptSerializer.new(@attempt),
          message: "¡Desafío completado exitosamente!",
          leaderboard_position: position,
          is_new_personal_best: @attempt.is_best_attempt?
        }
      else
        render json: {
          success: false,
          errors: @attempt.errors.full_messages
        }, status: :unprocessable_entity
      end

    rescue => e
      Rails.logger.error "Error in challenge_attempts#complete: #{e.message}"
      render json: {
        success: false,
        message: "Error al completar el intento"
      }, status: :internal_server_error
    end
  end

  # PUT /api/v1/challenges/:challenge_id/attempts/:id/abandon - Abandonar intento
  def abandon
    begin
      unless @attempt.in_progress?
        return render json: {
          success: false,
          message: "Este intento ya ha sido completado o abandonado"
        }, status: :unprocessable_entity
      end

      if @attempt.update(status: 'abandoned')
        render json: {
          success: true,
          data: ChallengeAttemptSerializer.new(@attempt),
          message: "Intento abandonado"
        }
      else
        render json: {
          success: false,
          errors: @attempt.errors.full_messages
        }, status: :unprocessable_entity
      end

    rescue => e
      Rails.logger.error "Error in challenge_attempts#abandon: #{e.message}"
      render json: {
        success: false,
        message: "Error al abandonar el intento"
      }, status: :internal_server_error
    end
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: "Desafío no encontrado"
    }, status: :not_found
  end

  def set_attempt
    @attempt = @challenge.challenge_attempts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: "Intento no encontrado"
    }, status: :not_found
  end

  def validate_user_access
    # Solo usuarios pueden crear intentos, y deben pertenecer al entrenador del desafío
    unless @current_user.user?
      return render json: {
        success: false,
        message: "Solo los usuarios pueden participar en desafíos"
      }, status: :forbidden
    end

    unless @current_user.coaches.include?(@challenge.coach)
      return render json: {
        success: false,
        message: "No tienes acceso a este desafío"
      }, status: :forbidden
    end

    unless @challenge.is_active_now?
      return render json: {
        success: false,
        message: "Este desafío no está activo"
      }, status: :unprocessable_entity
    end
  end
end
