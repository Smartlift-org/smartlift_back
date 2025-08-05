class WorkoutExercise < ApplicationRecord
  belongs_to :workout
  belongs_to :exercise
  belongs_to :routine_exercise, optional: true
  has_many :sets, class_name: "WorkoutSet", foreign_key: "workout_exercise_id", dependent: :destroy
  # Alias for backwards compatibility in serializers/tests
  has_many :workout_sets, class_name: "WorkoutSet", foreign_key: "workout_exercise_id", dependent: :destroy

  EXERCISE_GROUPS = {
    "regular" => "Single exercise",
    "superset" => "Two exercises performed back-to-back",
    "circuit" => "Multiple exercises in sequence"
  }.freeze

  validates :order, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :group_type, presence: true, inclusion: { in: EXERCISE_GROUPS.keys }
  validates :group_order, numericality: { only_integer: true, greater_than: 0 }, if: -> { group_type != "regular" }
  validates :target_sets, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :target_reps, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :suggested_weight, numericality: { greater_than: 0 }, allow_nil: true

  before_validation :set_default_order, on: :create
  before_validation :set_default_group_order, on: :create
  validate :validate_superset_size, if: :superset?

  scope :ordered, -> { order(:order) }
  scope :by_group, -> { order(:group_type, :group_order, :order) }
  scope :supersets, -> { where(group_type: "superset") }
  scope :circuits, -> { where(group_type: "circuit") }

  def completed_sets_count
    sets.completed.count
  end

  def total_volume
    sets.completed.sum(&:volume)
  end

  def average_weight
    completed = sets.completed
    return nil if completed.empty?
    completed.average(:weight)
  end

  def average_reps
    completed = sets.completed
    return nil if completed.empty?
    completed.average(:reps)
  end

  def average_rpe
    completed = sets.completed
    return nil if completed.empty?
    completed.average(:rpe)
  end

  def completed_as_prescribed?
    return false unless completed?

    completed_sets = sets.completed
    return false if completed_sets.count != target_sets

    completed_sets.all? do |set|
      set.reps == target_reps &&
      (suggested_weight.nil? || set.weight == suggested_weight)
    end
  end

  def completed?
    target_sets.present? && completed_sets_count >= target_sets
  end

  def in_progress?
    completed_sets_count > 0 && !completed?
  end

  def regular?
    group_type == "regular"
  end

  def superset?
    group_type == "superset"
  end

  def circuit?
    group_type == "circuit"
  end

  # Get all exercises in the same group
  def group_exercises
    return [ self ] if regular?

    workout.exercises
      .where(group_type: group_type, group_order: group_order)
      .ordered
  end

  # Record a new set for this exercise
  def record_set(weight:, reps:, rpe: nil, set_type: "normal", drop_set_weight: nil, drop_set_reps: nil)
    # Validate workout is still active
    unless workout.active?
      raise ActiveRecord::RecordInvalid.new(self).tap do |error|
        error.record.errors.add(:base, "Cannot add sets to inactive workout")
      end
    end

    sets.create!(
      weight: weight,
      reps: reps,
      rpe: rpe,
      set_type: set_type || "normal",
      drop_set_weight: drop_set_weight,
      drop_set_reps: drop_set_reps,
      completed: true,
      completed_at: Time.current
    )
  end

  # Mark exercise as completed and set final status
  def finalize!
    return false unless completed?

    update!(completed_at: Time.current)
  end

  # Calculate suggested weight based on user's history
  def calculate_suggested_weight
    return nil unless exercise

    # Get user's last successful weight for this exercise
    last_successful_set = WorkoutSet
      .joins(exercise: :workout)
      .where(
        workout_exercises: { exercise_id: exercise.id },
        workouts: {
          user_id: workout.user_id,
          status: "completed"
        },
        set_type: "normal"  # Only consider normal sets for progression
      )
      .where(completed: true)
      .order(created_at: :desc)
      .first

    if last_successful_set
      # Simple progressive overload: increase by 2.5-5% if all sets were completed
      last_successful_set.weight * 1.025
    else
      # Default starting weight based on exercise type could be implemented here
      nil
    end
  end

  private

  def set_default_order
    return if order.present?
    return unless workout.present?

    last_order = workout.exercises.maximum(:order) || 0
    self.order = last_order + 1
  end

  def set_default_group_order
    return if group_type == "regular" || group_order.present?

    last_group_order = workout.exercises
      .where(group_type: group_type)
      .maximum(:group_order) || 0
    self.group_order = last_group_order + 1
  end

  def validate_superset_size
    return unless workout.present? && group_order.present?

    existing_exercises = workout.exercises
      .where(group_type: "superset", group_order: group_order)
      .where.not(id: id) # Exclude current exercise if updating
      .count

    # Add 1 for the current exercise being validated
    total_exercises = existing_exercises + 1

    if total_exercises > 2
      errors.add(:group_type, "can only have 2 exercises in a superset")
    end
  end
end
