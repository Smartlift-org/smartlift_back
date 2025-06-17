class RoutineExercisesController < ApplicationController
  before_action :set_routine
  # JWT-based authentication is already handled by ApplicationController

  # POST /routines/:routine_id/exercises
  def create
    @routine_exercise = @routine.routine_exercises.build(routine_exercise_params)

    if @routine_exercise.save
      render json: @routine_exercise, status: :created
    else
      render json: { errors: @routine_exercise.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /routines/:routine_id/exercises/:id
  def destroy
    @routine_exercise = @routine.routine_exercises.find(params[:id])
    @routine_exercise.destroy
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Exercise not found in routine" }, status: :not_found
  end

  private

  def set_routine
    @routine = current_user.routines.find(params[:routine_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Routine not found" }, status: :not_found
  end

  def routine_exercise_params
    params.require(:routine_exercise).permit(
      :exercise_id,
      :sets,
      :reps,
      :rest_time,
      :order
    )
  end
end 