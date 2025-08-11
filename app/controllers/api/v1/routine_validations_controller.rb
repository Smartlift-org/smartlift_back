class Api::V1::RoutineValidationsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_trainer
  before_action :find_routine, only: [ :show, :approve, :reject ]

  # GET /api/v1/routine_validations
  # Lista rutinas pendientes de validación de los usuarios asignados al entrenador
  def index
    begin
      # Obtener IDs de usuarios asignados al entrenador actual
      assigned_user_ids = @current_user.users.pluck(:id)

      # Filtrar rutinas solo de usuarios asignados
      pending_routines = Routine.ai_generated
                                .pending_validation
                                .where(user_id: assigned_user_ids)
                                .includes(:user, routine_exercises: :exercise)
                                .order(created_at: :desc)

      render json: {
        success: true,
        data: {
          routines: pending_routines.map do |routine|
            {
              id: routine.id,
              name: routine.name,
              description: routine.description,
              difficulty: routine.difficulty,
              duration: routine.duration,
              source_type: routine.source_type,
              validation_status: routine.validation_status,
              created_at: routine.formatted_created_at,
              user: {
                id: routine.user.id,
                first_name: routine.user.first_name,
                last_name: routine.user.last_name,
                email: routine.user.email
              },
              exercises_count: routine.routine_exercises.count,
              ai_prompt_data: routine.ai_prompt_data
            }
          end,
          total_count: pending_routines.count
        }
      }, status: :ok

    rescue StandardError => e
      Rails.logger.error "Error fetching pending routines: #{e.message}"
      render json: {
        success: false,
        error: "Error al obtener rutinas pendientes",
        details: e.message
      }, status: :internal_server_error
    end
  end

  # GET /api/v1/routine_validations/:id
  # Obtiene detalles completos de una rutina para validación
  def show
    begin
      render json: {
        success: true,
        data: {
          routine: @routine.as_json.merge(
            validation_info: {
              source_type: @routine.source_type,
              validation_status: @routine.validation_status,
              ai_generated: @routine.ai_generated?,
              ai_prompt_data: @routine.ai_prompt_data
            }
          )
        }
      }, status: :ok

    rescue StandardError => e
      Rails.logger.error "Error fetching routine details: #{e.message}"
      render json: {
        success: false,
        error: "Error al obtener detalles de la rutina",
        details: e.message
      }, status: :internal_server_error
    end
  end

  # POST /api/v1/routine_validations/:id/approve
  # Aprueba una rutina generada por IA
  def approve
    begin
      unless @routine.pending_validation?
        return render json: {
          success: false,
          error: "Esta rutina ya ha sido validada"
        }, status: :unprocessable_entity
      end

      @routine.validate_routine!(current_user, params[:notes])

      render json: {
        success: true,
        message: "Rutina aprobada exitosamente",
        data: {
          routine: {
            id: @routine.id,
            name: @routine.name,
            validation_status: @routine.validation_status,
            validated_at: @routine.validated_at,
            validation_notes: @routine.validation_notes
          }
        }
      }, status: :ok

    rescue ActiveRecord::RecordInvalid => e
      render json: {
        success: false,
        error: "Error al aprobar la rutina",
        details: e.record.errors.full_messages
      }, status: :unprocessable_entity

    rescue StandardError => e
      Rails.logger.error "Error approving routine: #{e.message}"
      render json: {
        success: false,
        error: "Error interno al aprobar la rutina",
        details: e.message
      }, status: :internal_server_error
    end
  end

  # POST /api/v1/routine_validations/:id/reject
  # Rechaza una rutina generada por IA
  def reject
    begin
      unless @routine.pending_validation?
        return render json: {
          success: false,
          error: "Esta rutina ya ha sido validada"
        }, status: :unprocessable_entity
      end

      unless params[:notes].present?
        return render json: {
          success: false,
          error: "Las notas de rechazo son obligatorias"
        }, status: :bad_request
      end

      @routine.reject_routine!(current_user, params[:notes])

      render json: {
        success: true,
        message: "Rutina rechazada",
        data: {
          routine: {
            id: @routine.id,
            name: @routine.name,
            validation_status: @routine.validation_status,
            validated_at: @routine.validated_at,
            validation_notes: @routine.validation_notes
          }
        }
      }, status: :ok

    rescue ActiveRecord::RecordInvalid => e
      render json: {
        success: false,
        error: "Error al rechazar la rutina",
        details: e.record.errors.full_messages
      }, status: :unprocessable_entity

    rescue StandardError => e
      Rails.logger.error "Error rejecting routine: #{e.message}"
      render json: {
        success: false,
        error: "Error interno al rechazar la rutina",
        details: e.message
      }, status: :internal_server_error
    end
  end

  private

  def find_routine
    # Obtener IDs de usuarios asignados al entrenador actual
    assigned_user_ids = @current_user.users.pluck(:id)

    # Buscar rutina que sea IA y pertenezca a un usuario asignado
    @routine = Routine.ai_generated
                      .where(user_id: assigned_user_ids)
                      .find_by(id: params[:id])

    unless @routine
      render json: {
        success: false,
        error: "Rutina no encontrada, no es una rutina generada por IA, o no pertenece a uno de tus usuarios asignados"
      }, status: :not_found
      nil
    end
  end

  def ensure_trainer
    unless current_user&.role == "coach"
      render json: {
        success: false,
        error: "Acceso denegado. Solo los entrenadores pueden validar rutinas."
      }, status: :forbidden
    end
  end
end
