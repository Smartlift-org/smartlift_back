class MemberSummarySerializer
  def initialize(user)
    @user = user
  end

  def as_json
    {
      id: @user.id,
      name: "#{@user.first_name} #{@user.last_name}",
      email: @user.email,
      profile: profile_data,
      activity: activity_data,
      stats: stats_data,
      created_at: @user.created_at,
      last_activity: last_activity_date
    }
  end

  private

  def profile_data
    user_stat = @user.user_stat
    return basic_profile unless user_stat

    {
      height: user_stat.height,
      weight: user_stat.weight,
      age: user_stat.age,
      gender: user_stat.gender,
      fitness_goal: user_stat.fitness_goal,
      experience_level: user_stat.experience_level,
      available_days: user_stat.available_days,
      equipment_available: user_stat.equipment_available,
      activity_level: user_stat.activity_level,
      physical_limitations: user_stat.physical_limitations
    }
  end

  def basic_profile
    {
      height: nil,
      weight: nil,
      age: nil,
      gender: nil,
      fitness_goal: nil,
      experience_level: nil,
      available_days: nil,
      equipment_available: nil,
      activity_level: nil,
      physical_limitations: nil
    }
  end

  def activity_data
    workouts = @user.workouts
    recent_workouts = workouts.where(created_at: 30.days.ago..)

    {
      total_workouts: workouts.count,
      recent_workouts: recent_workouts.count,
      completed_workouts: workouts.where(status: "completed").count,
      this_month_workouts: workouts.where(created_at: Date.current.beginning_of_month..).count,
      last_workout_date: workouts.maximum(:created_at),
      activity_status: determine_activity_status(recent_workouts.count),
      consistency_score: calculate_consistency_score
    }
  end

  def stats_data
    completed_workouts = @user.workouts.where(status: "completed")

    return basic_stats if completed_workouts.empty?

    {
      total_volume: calculate_total_volume,
      average_workout_rating: calculate_average_rating,
      total_sets_completed: completed_workouts.sum(:total_sets_completed),
      total_exercises_completed: completed_workouts.sum(:total_exercises_completed),
      average_workout_duration: calculate_average_duration,
      personal_records_count: count_personal_records,
      favorite_exercises: get_favorite_exercises
    }
  end

  def basic_stats
    {
      total_volume: 0,
      average_workout_rating: nil,
      total_sets_completed: 0,
      total_exercises_completed: 0,
      average_workout_duration: nil,
      personal_records_count: 0,
      favorite_exercises: []
    }
  end

  def determine_activity_status(recent_workouts_count)
    case recent_workouts_count
    when 0
      "inactive"
    when 1..4
      "low"
    when 5..12
      "moderate"
    else
      "high"
    end
  end

  def calculate_consistency_score
    # Calculate workout consistency over last 8 weeks
    weeks = 8
    weeks_with_workouts = 0

    weeks.times do |i|
      week_start = i.weeks.ago.beginning_of_week
      week_end = i.weeks.ago.end_of_week

      if @user.workouts.where(created_at: week_start..week_end).exists?
        weeks_with_workouts += 1
      end
    end

    ((weeks_with_workouts.to_f / weeks) * 100).round(1)
  end

  def calculate_total_volume
    @user.workouts.where(status: "completed").sum(:total_volume) || 0
  end

  def calculate_average_rating
    ratings = @user.workouts.where(status: "completed").where.not(workout_rating: nil).pluck(:workout_rating)
    return nil if ratings.empty?

    (ratings.sum.to_f / ratings.length).round(1)
  end

  def calculate_average_duration
    durations = @user.workouts.where(status: "completed").where.not(total_duration_seconds: nil).pluck(:total_duration_seconds)
    return nil if durations.empty?

    (durations.sum / durations.length) # Returns seconds
  end

  def count_personal_records
    # Personal record functionality removed during optimization
    0
  end

  def get_favorite_exercises
    # Get top 3 most performed exercises
    @user.workouts
         .joins(workout_exercises: :exercise)
         .group("exercises.name")
         .order(Arel.sql("COUNT(*) DESC"))
         .limit(3)
         .pluck("exercises.name")
  end

  def last_activity_date
    @user.last_activity_at&.strftime('%Y-%m-%d')
  end
end
