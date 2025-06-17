class ExercisesController < ApplicationController
  before_action :set_exercise, only: [ :show, :update, :destroy ]
  before_action :authorize_exercise, only: [ :update, :destroy ]

  # GET /exercises
  def index
    @exercises = Exercise.all

    # Aplicar filtros si se proporcionan
    @exercises = @exercises.by_category(params[:category]) if params[:category].present?
    @exercises = @exercises.by_level(params[:level]) if params[:level].present?
    @exercises = @exercises.by_equipment(params[:equipment]) if params[:equipment].present?
    @exercises = @exercises.by_primary_muscle(params[:primary_muscle]) if params[:primary_muscle].present?
    @exercises = @exercises.by_secondary_muscle(params[:secondary_muscle]) if params[:secondary_muscle].present?
    @exercises = @exercises.search(params[:query]) if params[:query].present?

    render json: {
        exercises: @exercises.as_json(methods: [:predefined?]),
        total_count: @exercises.count
    }
  end

  # GET /exercises/:id
  def show
    render json: @exercise.as_json(methods: [:predefined?])
  end

  # POST /exercises
  def create
    @exercise = current_user.exercises.build(exercise_params)

    if @exercise.save
      render json: @exercise.as_json(methods: [:predefined?]), status: :created
    else
      render json: { errors: @exercise.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /exercises/:id
  def update
    if @exercise.update(exercise_params)
      render json: @exercise.as_json(methods: [:predefined?])
    else
      render json: { errors: @exercise.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /exercises/:id
  def destroy
    @exercise.destroy
    head :no_content
  end

  private

  def set_exercise
    @exercise = Exercise.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Exercise not found" }, status: :not_found
  end

  def authorize_exercise
    unless @exercise.user_id == current_user.id
      render json: { error: "Not authorized" }, status: :forbidden
    end
  end

  def exercise_params
    params.require(:exercise).permit(
      :name,
      :level,
      :force,
      :mechanic,
      :equipment,
      :category,
      :instructions,
      :primary_muscles,
      :secondary_muscles,
      :images
    )
  end
end
