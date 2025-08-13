class WorkoutSet < ApplicationRecord
  belongs_to :exercise, class_name: "WorkoutExercise", foreign_key: "workout_exercise_id"

  SET_TYPES = %w[normal warm_up failure].freeze

  validates :set_number, numericality: { only_integer: true, greater_than: 0 }
  validates :set_type, inclusion: { in: SET_TYPES }
  validates :reps, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true

  before_validation :set_set_number, on: :create
  before_validation :set_default_set_type, on: :create
  before_save :set_completed_at, if: :completed_changed?

  # Scopes
  scope :ordered, -> { order(:set_number) }
  scope :completed, -> { where(completed: true) }
  scope :in_progress, -> { where(completed: false) }
  scope :warm_up, -> { where(set_type: "warm_up") }
  scope :normal, -> { where(set_type: "normal") }
  scope :failure, -> { where(set_type: "failure") }

  def volume
    return 0 unless completed? && weight && reps
    weight * reps
  end

  def mark_as_completed!
    return false if completed?
    update!(completed: true, completed_at: Time.current)
  end

  def warm_up?
    set_type == "warm_up"
  end

  def failure?
    set_type == "failure"
  end

  def normal?
    set_type == "normal"
  end

  private

  def set_set_number
    return if set_number.present?
    return unless exercise.present?

    last_set_number = exercise.sets.maximum(:set_number) || 0
    self.set_number = last_set_number + 1
  end

  def set_default_set_type
    self.set_type ||= "normal"
  end

  def set_completed_at
    self.completed_at = Time.current if completed? && completed_at.nil?
  end
end
