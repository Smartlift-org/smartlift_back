class Workout::ExercisesController < Workout::BaseController
  before_action :set_workout
  before_action :set_workout_exercise, only: [ :show, :update, :destroy, :record_set, :complete, :finalize ]
  before_action :ensure_workout_active, only: [ :update, :record_set, :complete, :finalize ]

  # POST /workout/exercises
  def create
    @workout_exercise = @workout.exercises.new(workout_exercise_params)

    if @workout_exercise.save
      render json: @workout_exercise, status: :created
    else
      render json: @workout_exercise.errors, status: :unprocessable_entity
    end
  end

  # GET /workout/exercises
  def index
    @workout_exercises = @workout.exercises.includes(:sets).ordered
    @exercises = @workout_exercises  # For test compatibility
    render json: @workout_exercises
  end

  # GET /workout/exercises/:id
  def show
    @exercise = @workout_exercise  # For test compatibility
    render json: @workout_exercise
  end

  # PUT /workout/exercises/:id
  def update
    if @workout_exercise.update(workout_exercise_params)
      render json: @workout_exercise
    else
      render json: @workout_exercise.errors, status: :unprocessable_entity
    end
  end

  # DELETE /workout/exercises/:id
  def destroy
    @workout_exercise.destroy
    head :no_content
  end

  # POST /workout/exercises/:id/record_set
  def record_set
    weight = set_params[:weight].to_f
    reps = set_params[:reps].to_i
    rpe = set_params[:rpe].presence&.to_f
    set_type = set_params[:set_type] || "normal"
    drop_set_weight = set_params[:drop_set_weight].presence&.to_f
    drop_set_reps = set_params[:drop_set_reps].presence&.to_i

    begin
      Rails.logger.debug "Recording set for exercise #{@workout_exercise.id} with weight: #{weight}, reps: #{reps}, rpe: #{rpe}, set_type: #{set_type}"

      @workout_exercise.record_set(
        weight: weight,
        reps: reps,
        rpe: rpe,
        set_type: set_type,
        drop_set_weight: drop_set_weight,
        drop_set_reps: drop_set_reps
      )
      Rails.logger.debug "Set recorded successfully."

      render json: @workout_exercise.reload, status: :created
    rescue => e
      Rails.logger.error "Error recording set: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # PUT /workout/exercises/:id/complete
  def complete
    unless @workout_exercise.completed?
      render json: { error: "Exercise is not ready to be completed. Please complete all required sets first." }, status: :bad_request
      return
    end

    if @workout_exercise.finalize!
      render json: @workout_exercise
    else
      render json: @workout_exercise.errors, status: :unprocessable_entity
    end
  end

  # Alias for backward compatibility with tests
  alias_method :finalize, :complete

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
    @workout_exercise = @workout.exercises.find(params[:id])
  end

  def ensure_workout_active
    unless @workout.in_progress? || @workout.paused?
      render json: { error: "Cannot modify completed workout" }, status: :bad_request
      false
    end
  end

  def workout_exercise_params
    params.require(:workout_exercise).permit(
      :exercise_id,
      :order,
      :group_type,
      :group_order,
      :target_sets,
      :target_reps,
      :suggested_weight,
      :notes
    )
  end

  def set_params
    params.require(:set).permit(:weight, :reps, :rpe, :set_type, :drop_set_weight, :drop_set_reps)
  end
end
