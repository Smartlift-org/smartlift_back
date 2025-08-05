class WorkoutExerciseSerializer < ActiveModel::Serializer
  attributes :id,
             :workout_id,
             :exercise_id,
             :routine_exercise_id,
             :order,
             :group_type,
             :group_order,
             :target_sets,
             :target_reps,
             :suggested_weight,
             :notes,
             :started_at,
             :completed_at,
             :created_at,
             :updated_at

  belongs_to :exercise
  belongs_to :routine_exercise
  has_many :sets, serializer: WorkoutSetSerializer

  # Calculated attributes
  def completed_sets_count
    object.completed_sets_count
  end

  def total_volume
    object.total_volume
  end

  def average_weight
    object.average_weight
  end

  def average_reps
    object.average_reps
  end

  def average_rpe
    object.average_rpe
  end

  def completed?
    object.completed?
  end

  def in_progress?
    object.in_progress?
  end

  attributes :completed_sets_count, :total_volume, :average_weight,
             :average_reps, :average_rpe, :completed?, :in_progress?
end
