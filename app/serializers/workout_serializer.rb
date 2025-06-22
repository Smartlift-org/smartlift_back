class WorkoutSerializer < ActiveModel::Serializer
  attributes :id,
             :routine_id,
             :workout_type,
             :name,
             :status,
             :started_at,
             :completed_at,
             :total_duration_seconds,
             :total_volume,
             :total_sets_completed,
             :total_exercises_completed,
             :average_rpe,
             :perceived_intensity,
             :energy_level,
             :mood,
             :notes,
             :followed_routine,
             :created_at,
             :updated_at

  belongs_to :user
  belongs_to :routine
  has_many :exercises, serializer: WorkoutExerciseSerializer
  has_many :pauses, serializer: WorkoutPauseSerializer

  def total_duration_seconds
    object.total_duration_seconds || object.actual_duration.to_i
  end

  def total_volume
    object.total_volume || 0
  end

  def total_sets_completed
    object.total_sets_completed || 0
  end

  def total_exercises_completed
    object.total_exercises_completed || 0
  end

  def average_rpe
    object.average_rpe || 0
  end

  def display_name
    object.display_name
  end

  def has_exercises?
    object.has_exercises?
  end

  def routine_based?
    object.routine_based?
  end

  def free_style?
    object.free_style?
  end

  attributes :display_name, :has_exercises?, :routine_based?, :free_style?
end 