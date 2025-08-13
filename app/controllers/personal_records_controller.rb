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
    # Personal record functionality removed during optimization
    render json: []
  end

  # GET /personal_records/recent
  def recent
    # Personal record functionality removed during optimization
    render json: []
  end

  # GET /personal_records/:id
  def show
    # Personal record functionality removed during optimization
    raise ActiveRecord::RecordNotFound
  end

  # GET /personal_records/latest
  def latest
    # Personal record functionality removed during optimization
    render json: []
  end

  # GET /personal_records/statistics
  def statistics
    # Personal record functionality removed during optimization
    @statistics = {
      total_prs: 0,
      weight_prs: 0,
      reps_prs: 0,
      volume_prs: 0,
      exercises_with_prs: 0,
      recent_prs_this_week: 0,
      recent_prs_this_month: 0
    }

    render json: @statistics
  end
end
