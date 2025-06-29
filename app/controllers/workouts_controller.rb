class WorkoutsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workout, except: [:index, :create, :create_free]
  before_action :ensure_workout_active, only: [:pause, :resume, :complete]

  # POST /workouts
  def create
    @workout = current_user.workouts.new(workout_params)
    @workout.started_at = Time.current

    if @workout.save
      render json: @workout, status: :created
    else
      render json: @workout.errors, status: :unprocessable_entity
    end
  end

  # POST /workouts/free
  def create_free
    @workout = current_user.workouts.new(free_workout_params)
    @workout.workout_type = 'free_style'
    @workout.started_at = Time.current

    if @workout.save
      render json: @workout, status: :created
    else
      render json: @workout.errors, status: :unprocessable_entity
    end
  end

  # GET /workouts
  def index
    @workouts = current_user.workouts.includes(:exercises).recent
    render json: @workouts
  end

  # GET /workouts/:id
  def show
    render json: @workout
  end

  # PUT /workouts/:id/pause
  def pause
    if @workout.pause!
      render json: @workout
    else
      render json: { error: "Could not pause workout" }, status: :unprocessable_entity
    end
  end

  # PUT /workouts/:id/resume
  def resume
    if @workout.resume!
      render json: @workout
    else
      render json: { error: "Could not resume workout" }, status: :unprocessable_entity
    end
  end

  # PUT /workouts/:id/complete
  def complete
    if @workout.complete!
      @workout.update!(completion_params) if completion_params.present?
      render json: @workout
    else
      error_messages = @workout.errors.full_messages.presence || ["Could not complete workout"]
      render json: { errors: error_messages }, status: :unprocessable_entity
    end
  end

  # PUT /workouts/:id/abandon
  def abandon
    return render json: { error: "Cannot abandon a completed workout" }, status: :unprocessable_entity if @workout.completed?
    
    if @workout.abandon!
      render json: @workout
    else
      render json: { error: "Could not abandon workout" }, status: :unprocessable_entity
    end
  end

  private

  def set_workout
    @workout = current_user.workouts.find(params[:id])
  end

  def ensure_workout_active
    unless @workout.active?
      render json: { error: "Workout is not active" }, status: :bad_request
    end
  end

  def workout_params
    params.require(:workout).permit(:routine_id, :name, :workout_type)
  end

  def free_workout_params
    params.require(:workout).permit(:name)
  end


  def completion_params
    params.permit(:perceived_intensity, :energy_level, :mood, :notes)
  end
end 