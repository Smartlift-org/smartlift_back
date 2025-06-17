class RoutinesController < ApplicationController
  before_action :set_routine, only: [:show, :update, :destroy]
  # JWT-based authentication is already handled by ApplicationController

  # GET /routines
  def index
    @routines = current_user.routines

    # Aplicar filtros si se proporcionan
    @routines = @routines.by_level(params[:level]) if params[:level].present?
    @routines = @routines.by_duration(params[:max_duration]) if params[:max_duration].present?
    @routines = @routines.by_muscle_group(params[:muscle_group]) if params[:muscle_group].present?
    @routines = @routines.search(params[:query]) if params[:query].present?

    # Paginación
    @routines = @routines.page(params[:page]).per(params[:per_page] || 10)

    render json: {
      routines: @routines.as_json,
      total_pages: @routines.total_pages,
      current_page: @routines.current_page,
      total_count: @routines.total_count
    }
  end

  # GET /routines/:id
  def show
    render json: @routine.as_json
  end

  # POST /routines
  def create
    @routine = current_user.routines.build(routine_params)

    if @routine.save
      render json: @routine.as_json, status: :created
    else
      render json: { errors: @routine.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /routines/:id
  def update
    ActiveRecord::Base.transaction do
      if @routine.update(routine_params)
        # Reload to get the updated associations
        @routine.reload
        render json: @routine.as_json
      else
        render json: { errors: @routine.errors.full_messages }, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { errors: [e.message] }, status: :unprocessable_entity
  end

  # DELETE /routines/:id
  def destroy
    @routine.destroy
    head :no_content
  end

  private

  def set_routine
    @routine = current_user.routines.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Routine not found" }, status: :not_found
  end

  def routine_params
    params.require(:routine).permit(
      :name,
      :description,
      :level,
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
end 