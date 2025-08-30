class ExercisesController < ApplicationController
  before_action :set_exercise, only: [:show, :update, :destroy]

  # GET /exercises
  def index
    @exercises = Exercise.all
    
    # Aplicar filtros si existen
    @exercises = @exercises.by_category(params[:category]) if params[:category].present?
    @exercises = @exercises.by_difficulty(params[:difficulty]) if params[:difficulty].present?
    @exercises = @exercises.by_equipment(params[:equipment]) if params[:equipment].present?
    @exercises = @exercises.by_primary_muscle(params[:primary_muscle]) if params[:primary_muscle].present?
    @exercises = @exercises.by_secondary_muscle(params[:secondary_muscle]) if params[:secondary_muscle].present?
    @exercises = @exercises.search(params[:query]) if params[:query].present?

    # Paginación
    render json: {
      exercises: @exercises.as_json(methods: [:image_urls, :difficulty_level, :has_equipment?]),
    }, status: :ok
  end

  # GET /exercises/:id
  def show
    render json: @exercise.as_json(methods: [:image_urls, :difficulty_level, :has_equipment?]), status: :ok
  end

  # POST /exercises
  def create
    @exercise = Exercise.new(exercise_params)

    if @exercise.save
      render json: @exercise.as_json(methods: [:image_urls, :difficulty_level, :has_equipment?]), status: :created
    else
      render json: { errors: @exercise.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /exercises/:id
  def update
    if @exercise.update(exercise_params)
      render json: @exercise.as_json(methods: [:image_urls, :difficulty_level, :has_equipment?]), status: :ok
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
    render json: { error: 'Exercise not found' }, status: :not_found
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
      primary_muscles: [],
      secondary_muscles: [],
      instructions: [],
      images: []
    )
  end
end
