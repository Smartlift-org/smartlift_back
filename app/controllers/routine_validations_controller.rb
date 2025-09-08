class RoutineValidationsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_trainer
  before_action :find_routine, only: [ :show, :approve, :reject ]

  # GET /routine_validations
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

  # GET /routine_validations/:id
  # Obtiene detalles completos de una rutina para validación
  def show
    begin
      render json: {
        success: true,
        data: @routine.as_json(
          include: {
            user: { only: [:id, :first_name, :last_name] },
            routine_exercises: {
              include: {
                exercise: { only: [:id, :name, :primary_muscles] }
              }
            }
          }
        ).merge(
          validation_info: {
            source_type: @routine.source_type,
            validation_status: @routine.validation_status,
            ai_generated: @routine.ai_generated?,
            ai_prompt_data: @routine.ai_prompt_data
          }
        )
      }, status: :ok

    rescue StandardError => e
      Rails.logger.error "Error fetching routine details: #{e.message}"
      render json: {
        success: false,
        error: "Error al obtener detalles de la rutina",
        details: e.message
      }, status: :internal_server_error
    end
  end

  # POST /routine_validations/:id/approve
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

  # PUT /routine_validations/:id/edit
  # Edita una rutina IA pendiente y opcionalmente la valida
  def edit
    begin
      unless @routine.pending_validation?
        return render json: {
          success: false,
          error: "Solo se pueden editar rutinas pendientes de validación"
        }, status: :unprocessable_entity
      end

      # Validar parámetros de edición
      edit_errors = validate_edit_params
      if edit_errors.any?
        return render json: {
          success: false,
          error: "Datos de edición inválidos",
          details: edit_errors
        }, status: :bad_request
      end

      # Actualizar la rutina
      if @routine.update(routine_edit_params)
        # Si se especifica auto-validar después de editar
        if params[:auto_validate] == true
          @routine.validate_routine!(current_user, params[:validation_notes])
        end

        render json: {
          success: true,
          message: params[:auto_validate] ? "Rutina editada y validada exitosamente" : "Rutina editada exitosamente",
          data: {
            routine: @routine.as_json.merge(
              validation_info: {
                validation_status: @routine.validation_status,
                validated_at: @routine.validated_at,
                validation_notes: @routine.validation_notes
              }
            )
          }
        }, status: :ok
      else
        render json: {
          success: false,
          error: "Error al actualizar la rutina",
          details: @routine.errors.full_messages
        }, status: :unprocessable_entity
      end

    rescue ActiveRecord::RecordInvalid => e
      render json: {
        success: false,
        error: "Error de validación",
        details: e.record.errors.full_messages
      }, status: :unprocessable_entity

    rescue StandardError => e
      Rails.logger.error "Error editing routine: #{e.message}"
      render json: {
        success: false,
        error: "Error interno al editar la rutina",
        details: e.message
      }, status: :internal_server_error
    end
  end

  # POST /routine_validations/:id/reject
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

  def validate_edit_params
    errors = []

    # Validar que al menos un campo esté presente para editar
    editable_fields = [:name, :description, :difficulty, :duration, :routine_exercises_attributes]
    has_editable_field = editable_fields.any? { |field| params[field].present? }

    unless has_editable_field
      errors << "Debe especificar al menos un campo para editar"
      return errors
    end

    # Validar name si está presente
    if params[:name].present?
      if params[:name].to_s.length < 3
        errors << "El nombre debe tener al menos 3 caracteres"
      elsif params[:name].to_s.length > 100
        errors << "El nombre no puede tener más de 100 caracteres"
      end
    end

    # Validar description si está presente
    if params[:description].present?
      if params[:description].to_s.length < 10
        errors << "La descripción debe tener al menos 10 caracteres"
      elsif params[:description].to_s.length > 1000
        errors << "La descripción no puede tener más de 1000 caracteres"
      end
    end

    # Validar difficulty si está presente
    if params[:difficulty].present?
      unless %w[beginner intermediate advanced].include?(params[:difficulty].to_s)
        errors << "La dificultad debe ser: beginner, intermediate o advanced"
      end
    end

    # Validar duration si está presente
    if params[:duration].present?
      duration_int = params[:duration].to_i
      if duration_int <= 0 || duration_int > 180
        errors << "La duración debe estar entre 1 y 180 minutos"
      end
    end

    # Validar routine_exercises_attributes si está presente
    if params[:routine_exercises_attributes].present?
      unless params[:routine_exercises_attributes].is_a?(Array)
        errors << "Los ejercicios deben ser un array"
      else
        params[:routine_exercises_attributes].each_with_index do |exercise_attrs, index|
          exercise_errors = validate_routine_exercise_attributes(exercise_attrs, index)
          errors.concat(exercise_errors)
        end
      end
    end

    errors
  end

  def validate_routine_exercise_attributes(attrs, index)
    errors = []

    # Si es para eliminar, solo validar que tenga _destroy
    if attrs[:_destroy] == "1" || attrs[:_destroy] == true
      return errors
    end

    # Validar exercise_id
    if attrs[:exercise_id].blank?
      errors << "Ejercicio #{index + 1}: exercise_id es requerido"
    elsif attrs[:exercise_id].to_i <= 0
      errors << "Ejercicio #{index + 1}: exercise_id debe ser un entero positivo"
    end

    # Validar sets
    if attrs[:sets].present?
      sets_int = attrs[:sets].to_i
      if sets_int <= 0 || sets_int > 20
        errors << "Ejercicio #{index + 1}: sets debe estar entre 1 y 20"
      end
    end

    # Validar reps
    if attrs[:reps].present?
      reps_int = attrs[:reps].to_i
      if reps_int <= 0 || reps_int > 100
        errors << "Ejercicio #{index + 1}: reps debe estar entre 1 y 100"
      end
    end

    # Validar rest_time si está presente
    if attrs[:rest_time].present?
      rest_time_int = attrs[:rest_time].to_i
      if rest_time_int < 0 || rest_time_int > 600
        errors << "Ejercicio #{index + 1}: rest_time debe estar entre 0 y 600 segundos"
      end
    end

    # Validar order si está presente
    if attrs[:order].present?
      order_int = attrs[:order].to_i
      if order_int <= 0
        errors << "Ejercicio #{index + 1}: order debe ser un entero positivo"
      end
    end

    errors
  end

  def routine_edit_params
    params.permit(
      :name,
      :description,
      :difficulty,
      :duration,
      routine_exercises_attributes: [
        :id,
        :exercise_id,
        :sets,
        :reps,
        :rest_time,
        :order,
        :_destroy
      ]
    )
  end

  def find_routine
    # Obtener IDs de usuarios asignados al entrenador actual
    assigned_user_ids = @current_user.users.pluck(:id)

    # Buscar rutina que sea IA y pertenezca a un usuario asignado
    @routine = Routine.ai_generated
                      .includes(:user, routine_exercises: :exercise)
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
