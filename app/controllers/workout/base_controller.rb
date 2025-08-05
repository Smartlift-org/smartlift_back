class Workout::BaseController < ApplicationController
  # La autenticación ya se maneja en ApplicationController con authorize_request

  private

  def current_workout
    @current_workout ||= current_user.workouts.active.first
  end

  def ensure_active_workout
    unless current_workout
      render json: { error: "No active workout found" }, status: :not_found
    end
  end

  def current_workout_exercise
    @current_workout_exercise ||= current_workout.exercises.find(params[:workout_exercise_id])
  end
end
