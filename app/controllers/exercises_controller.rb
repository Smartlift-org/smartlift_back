class ExercisesController < ApplicationController
  # Skip authentication for read-only operations (index, show)
  skip_before_action :authorize_request, only: [:index, :show]
  before_action :set_exercise, only: [ :show, :update, :destroy ]

  # GET /exercises
  def index
    @exercises = Exercise.all

    # Aplicar filtros si existen
    @exercises = @exercises.by_level(params[:level]) if params[:level].present?
    @exercises = @exercises.by_primary_muscle(params[:primary_muscle]) if params[:primary_muscle].present?
    @exercises = @exercises.search(params[:query]) if params[:query].present?

    # Paginación
    render json: {
      exercises: @exercises.as_json(methods: [ :difficulty_level ])
    }, status: :ok
  end

  # GET /exercises/:id
  def show
    render json: @exercise.as_json(methods: [ :difficulty_level ]), status: :ok
  end

  # POST /exercises
  def create
    @exercise = Exercise.new(exercise_params)

    if @exercise.save
      render json: @exercise.as_json(methods: [ :difficulty_level ]), status: :created
    else
      render json: { errors: @exercise.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /exercises/:id
  def update
    if @exercise.update(exercise_params)
      render json: @exercise.as_json(methods: [ :difficulty_level ]), status: :ok
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

  def exercise_params
    params.require(:exercise).permit(
      :name,
      :level,
      :instructions,
      primary_muscles: [],
      images: []
    )
  end
end
