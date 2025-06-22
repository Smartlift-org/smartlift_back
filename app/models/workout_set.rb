class WorkoutSet < ApplicationRecord
  belongs_to :exercise, class_name: 'WorkoutExercise', foreign_key: 'workout_exercise_id'

  SET_TYPES = %w[warm_up normal failure drop_set].freeze
  PR_TYPES = %w[weight reps volume].freeze

  validates :set_number, numericality: { only_integer: true, greater_than: 0 }
  validates :set_type, inclusion: { in: SET_TYPES }
  validates :reps, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true
  validates :rest_time_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :rpe, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }, allow_nil: true
  validates :drop_set_weight, numericality: { greater_than: 0 }, if: :drop_set?
  validates :drop_set_reps, numericality: { only_integer: true, greater_than: 0 }, if: :drop_set?
  validates :pr_type, inclusion: { in: PR_TYPES }, if: :is_personal_record
  
  before_validation :set_set_number, on: :create
  before_validation :set_default_set_type, on: :create
  before_save :set_completed_at, if: :completed_changed?

  # Scopes
  scope :ordered, -> { order(:set_number) }
  scope :completed, -> { where(completed: true) }
  scope :in_progress, -> { where(completed: false) }
  scope :warm_up, -> { where(set_type: 'warm_up') }
  scope :normal, -> { where(set_type: 'normal') }
  scope :failure, -> { where(set_type: 'failure') }
  scope :drop_sets, -> { where(set_type: 'drop_set') }
  scope :personal_records, -> { where(is_personal_record: true) }

  def volume
    return 0 unless completed? && weight && reps
    if drop_set?
      (weight * reps) + (drop_set_weight * drop_set_reps)
    else
      weight * reps
    end
  end

  def check_for_personal_records
    return unless completed? && normal?  # Only check PRs for normal sets
    return if is_personal_record?  # Don't overwrite existing PRs
    
    exercise_model = exercise.exercise
    user = exercise.workout.user
    
    # Get previous records with optimized query
    previous_sets = WorkoutSet
      .joins(exercise: :workout)
      .where(
        workout_exercises: { exercise_id: exercise_model.id },
        workouts: { 
          user_id: user.id,
          status: 'completed'  # Only consider completed workouts
        },
        completed: true,
        set_type: 'normal'
      )
      .where.not(id: id)
      .select(:id, :weight, :reps, :workout_exercise_id)  # Only select needed columns

    pr_detected = false

    # Check weight PR first (highest priority)
    if weight.present? && (previous_sets.maximum(:weight) || 0) < weight
      update_columns(is_personal_record: true, pr_type: 'weight')
      pr_detected = true
    end

    # Check reps PR if no weight PR was detected
    if !pr_detected && reps.present? && weight.present?
      max_reps_at_weight = previous_sets.where(weight: weight).maximum(:reps) || 0
      if reps > max_reps_at_weight
        update_columns(is_personal_record: true, pr_type: 'reps')
        pr_detected = true
      end
    end

    # Check volume PR if no other PR was detected
    if !pr_detected
      current_volume = volume
      if current_volume > 0
        max_volume = previous_sets.map(&:volume).max || 0
        if current_volume > max_volume
          update_columns(is_personal_record: true, pr_type: 'volume')
        end
      end
    end
  end

  def duration
    return 0 unless started_at && completed_at
    completed_at - started_at
  end

  def start!
    return false if started_at.present?
    update!(started_at: Time.current)
  end

  def complete!(actual_reps: nil, actual_weight: nil, drop_set_data: nil)
    return false if completed?
    
    attributes = {
      completed: true,
      completed_at: Time.current
    }
    
    attributes[:reps] = actual_reps if actual_reps.present?
    attributes[:weight] = actual_weight if actual_weight.present?

    if drop_set? && drop_set_data.present?
      attributes[:drop_set_weight] = drop_set_data[:weight]
      attributes[:drop_set_reps] = drop_set_data[:reps]
    end
    
    update!(attributes)
  end

  def mark_as_completed!
    return false if completed?
    update!(completed: true, completed_at: Time.current)
  end

  def drop_set?
    set_type == 'drop_set'
  end

  def warm_up?
    set_type == 'warm_up'
  end

  def failure?
    set_type == 'failure'
  end

  def normal?
    set_type == 'normal'
  end

  private

  def set_set_number
    return if set_number.present?
    return unless exercise.present?
    
    last_set_number = exercise.sets.maximum(:set_number) || 0
    self.set_number = last_set_number + 1
  end

  def set_default_set_type
    self.set_type ||= 'normal'
  end

  def set_completed_at
    self.completed_at = Time.current if completed? && completed_at.nil?
  end
end 