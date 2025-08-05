class Workout::SetsController < Workout::BaseController
  before_action :set_workout
  before_action :set_workout_exercise
  before_action :set_workout_set, only: [ :show, :update, :destroy, :complete, :start, :mark_as_completed ]
  before_action :ensure_workout_active, only: [ :create, :update, :complete, :start ]
  before_action :ensure_set_not_completed, only: [ :update, :start ]

  # POST /workout/exercises/:exercise_id/sets
  def create
    @workout_set = @workout_exercise.sets.new(workout_set_params)

    if @workout_set.save
      render json: @workout_set, status: :created
    else
      render json: @workout_set.errors, status: :unprocessable_entity
    end
  end

  # GET /workout/exercises/:exercise_id/sets
  def index
    @workout_sets = @workout_exercise.sets.ordered
    @sets = @workout_sets  # For test compatibility
    render json: @workout_sets
  end

  # GET /workout/exercises/:exercise_id/sets/:id
  def show
    @set = @workout_set  # For test compatibility
    render json: @workout_set
  end

  # PUT /workout/exercises/:exercise_id/sets/:id
  def update
    if @workout_set.update(workout_set_params)
      render json: @workout_set
    else
      render json: @workout_set.errors, status: :unprocessable_entity
    end
  end

  # DELETE /workout/exercises/:exercise_id/sets/:id
  def destroy
    if @workout_set.completed?
      render json: { error: "Cannot delete completed set" }, status: :bad_request
      return
    end

    @workout_set.destroy
    head :no_content
  end

  # PUT /workout/exercises/:exercise_id/sets/:id/complete
  def complete
    if @workout_set.completed?
      render json: { error: "Set is already completed" }, status: :bad_request
      return
    end

    # Get completion data from params (standardized with nested structure)
    completion_data = completion_set_params

    # Map actual_* to standard names if needed (backward compatibility)
    completion_data[:weight] = completion_data[:actual_weight] if completion_data[:actual_weight].present?
    completion_data[:reps] = completion_data[:actual_reps] if completion_data[:actual_reps].present?

    # Validate required completion data
    if completion_data[:weight].blank? || completion_data[:reps].blank?
      render json: { error: "Weight and reps are required for completion" }, status: :unprocessable_entity
      return
    end

    # Update the set with completion data
    @workout_set.assign_attributes(completion_data.except(:actual_weight, :actual_reps))
    @workout_set.completed = true
    @workout_set.completed_at = Time.current

    if @workout_set.save
      render json: @workout_set
    else
      render json: @workout_set.errors, status: :unprocessable_entity
    end
  end

  # PUT /workout/exercises/:exercise_id/sets/:id/mark_as_completed
  def mark_as_completed
    if @workout_set.completed?
      render json: { error: "Set is already completed" }, status: :bad_request
      return
    end

    @workout_set.completed = true
    @workout_set.completed_at = Time.current

    if @workout_set.save
      render json: @workout_set
    else
      render json: @workout_set.errors, status: :unprocessable_entity
    end
  end

  # PUT /workout/exercises/:exercise_id/sets/:id/start
  def start
    if @workout_set.started_at.present?
      render json: { error: "Set has already been started" }, status: :bad_request
      return
    end

    if @workout_set.start!
      render json: @workout_set
    else
      render json: @workout_set.errors, status: :unprocessable_entity
    end
  end

  private

  def set_workout
    @workout = current_user.workouts.find(params[:workout_id]) if params[:workout_id]
    @workout ||= current_workout

    unless @workout
      render json: { error: "No active workout found" }, status: :not_found
      nil
    end
  end

  def set_workout_exercise
    @workout_exercise = @workout.exercises.find(params[:exercise_id])
  end

  def set_workout_set
    @workout_set = @workout_exercise.sets.find(params[:id])
  end

  def ensure_workout_active
    unless @workout.in_progress? || @workout.paused?
      render json: { error: "Cannot modify completed workout" }, status: :bad_request
      false
    end
  end

  def ensure_set_not_completed
    if @workout_set&.completed?
      render json: { error: "Cannot modify completed set" }, status: :bad_request
      false
    end
  end

  def workout_set_params
    params.require(:set).permit(
      :set_number,
      :set_type,
      :weight,
      :reps,
      :rpe,
      :rest_time_seconds,
      :notes,
      :drop_set_weight,
      :drop_set_reps
    )
  end

  def completion_set_params
    # Support both nested and direct parameter formats for backward compatibility
    if params[:set].present?
      params.require(:set).permit(:weight, :reps, :actual_weight, :actual_reps, :rpe, :drop_set_weight, :drop_set_reps)
    else
      # Fallback to direct params for backward compatibility
      params.permit(:weight, :reps, :actual_weight, :actual_reps, :rpe, :drop_set_weight, :drop_set_reps)
    end
  end
end
