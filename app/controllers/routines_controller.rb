class RoutinesController < ApplicationController
  before_action :set_routine, only: [ :show, :update, :destroy ]
  # JWT-based authentication is already handled by ApplicationController

  # GET /routines
  def index
    @routines = current_user.routines

    # Apply filters if they exist
    @routines = @routines.where(difficulty: params[:difficulty]) if params[:difficulty].present?
    @routines = @routines.where("duration <= ?", params[:max_duration]) if params[:max_duration].present?
    @routines = @routines.where("duration >= ?", params[:min_duration]) if params[:min_duration].present?

    render json: @routines, status: :ok
  end

  # GET /routines/:id
  def show
    render json: @routine, status: :ok
  end

  # POST /routines
  def create
    @routine = current_user.routines.build(routine_params)

    if @routine.save
      render json: @routine, status: :created
    else
      render json: { errors: @routine.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /routines/:id
  def update
    if @routine.update(routine_params)
      render json: @routine, status: :ok
    else
      render json: { errors: @routine.errors.full_messages }, status: :unprocessable_entity
    end
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
      :difficulty,
      :duration,
      # AI validation fields
      :source_type,
      :validation_status,
      :ai_generated,
      :validated_by_id,
      :validation_notes,
      :ai_prompt_data,
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
