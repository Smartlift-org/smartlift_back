class Workout::PausesController < Workout::BaseController
  before_action :set_workout
  before_action :set_workout_pause, only: [:show, :resume, :destroy]

  # POST /workout/pauses
  def create
    unless @workout.active? && !@workout.paused?
      render json: { error: "Cannot pause this workout" }, status: :bad_request
      return
    end

    if @workout.pause!(pause_params[:reason])
      render json: @workout.pauses.last, status: :created
    else
      render json: { error: "Could not pause workout" }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /workout/pauses
  def index
    @pauses = @workout.pauses.order(paused_at: :desc)
    render json: @pauses
  end

  # GET /workout/pauses/:id
  def show
    @pause = @workout_pause  # For test compatibility
    render json: @workout_pause
  end

  # PUT /workout/pauses/:id/resume
  def resume
    if @workout_pause.completed?
      render json: { error: "Cannot resume a completed pause" }, status: :bad_request
      return
    end

    unless @workout.paused?
      render json: { error: "Workout is not paused" }, status: :bad_request
      return
    end

    if @workout.resume!
      render json: @workout_pause.reload
    else
      render json: { error: "Could not resume workout" }, status: :unprocessable_entity
    end
  end

  # DELETE /workout/pauses/:id
  def destroy
    if @workout_pause.active? && @workout_pause.destroy
      @workout.update!(status: 'in_progress') if @workout.paused?
      head :no_content
    else
      render json: { error: "Cannot delete completed pause" }, status: :bad_request
    end
  end

  # GET /workout/pauses/current
  def current
    active_pause = @workout.pauses.where(resumed_at: nil).first
    if active_pause
      @pause = active_pause  # For test compatibility
      render json: active_pause
    else
      render json: { error: "No active pause found" }, status: :not_found
    end
  end

  private

  def set_workout
    @workout = current_user.workouts.find(params[:workout_id]) if params[:workout_id]
    @workout ||= current_workout
    
    unless @workout
      render json: { error: "No active workout found" }, status: :not_found
      return
    end
  end

  def set_workout_pause
    @workout_pause = @workout.pauses.find(params[:id])
  end

  def pause_params
    params.require(:pause).permit(:reason)
  end
end 