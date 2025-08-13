class PersonalRecordsController < ApplicationController
  before_action :authenticate_user!

  # GET /personal_records
  def index
    # Personal record functionality removed during optimization
    @personal_records = WorkoutSet.none

    # Apply filters
    base_query = base_query.where(exercises: { id: params[:exercise_id] }) if params[:exercise_id]
    base_query = base_query.where(pr_type: params[:pr_type]) if params[:pr_type]

    @personal_records = base_query
      .includes(exercise: [ :exercise, { workout: :user } ])
      .order(created_at: :desc)
      .limit(params[:limit] || 50)

    render json: @personal_records
  end

  # GET /personal_records/by_exercise/:exercise_id
  def by_exercise
    exercise = Exercise.find(params[:exercise_id])

    @personal_records = WorkoutSet
      .joins(exercise: [ :exercise, :workout ])
      .where(
        exercises: { id: exercise.id },
        workouts: { user_id: current_user.id },
        is_personal_record: true,
        completed: true
      )
      .includes(exercise: [ :exercise, :workout ])
      .order(created_at: :desc)

    render json: @personal_records
  end

  # GET /personal_records/recent
  def recent
    @personal_records = WorkoutSet
      .joins(exercise: [ :exercise, :workout ])
      .where(
        workouts: { user_id: current_user.id },
        is_personal_record: true,
        completed: true
      )
      .where("workout_sets.created_at >= ?", 1.month.ago)
      .includes(exercise: [ :exercise, :workout ])
      .order(created_at: :desc)

    render json: @personal_records
  end

  # GET /personal_records/:id
  def show
    @personal_record = WorkoutSet
      .joins(exercise: [ :exercise, :workout ])
      .where(
        workouts: { user_id: current_user.id },
        is_personal_record: true,
        id: params[:id]
      )
      .includes(exercise: [ :exercise, :workout ])
      .first

    if @personal_record
      render json: @personal_record
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  # GET /personal_records/latest
  def latest
    days = params[:days]&.to_i || 7
    limit = params[:limit]&.to_i

    @personal_records = WorkoutSet
      .joins(exercise: [ :exercise, :workout ])
      .where(
        workouts: { user_id: current_user.id },
        is_personal_record: true,
        completed: true
      )
      .where("workout_sets.created_at >= ?", days.days.ago)
      .includes(exercise: [ :exercise, :workout ])
      .order(created_at: :desc)

    @personal_records = @personal_records.limit(limit) if limit

    render json: @personal_records
  end

  # GET /personal_records/statistics
  def statistics
    base_query = WorkoutSet
      .joins(exercise: [ :exercise, :workout ])
      .where(
        workouts: { user_id: current_user.id },
        is_personal_record: true,
        completed: true
      )

    @statistics = {
      total_prs: base_query.count,
      weight_prs: base_query.where(pr_type: "weight").count,
      reps_prs: base_query.where(pr_type: "reps").count,
      volume_prs: base_query.where(pr_type: "volume").count,
      exercises_with_prs: base_query.distinct.count("exercises.id"),
      recent_prs_this_week: base_query.where("workout_sets.created_at >= ?", 1.week.ago).count,
      recent_prs_this_month: base_query.where("workout_sets.created_at >= ?", 1.month.ago).count
    }

    render json: @statistics
  end
end
