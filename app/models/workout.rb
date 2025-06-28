class Workout < ApplicationRecord
  include WorkoutTrackable
  
  attr_accessor :skip_active_workout_validation
  
  belongs_to :user
  belongs_to :routine, optional: true
  has_many :exercises, class_name: 'WorkoutExercise', dependent: :destroy
  has_many :pauses, class_name: 'WorkoutPause', dependent: :destroy
  has_many :performed_exercises, through: :exercises, source: :exercise

  enum workout_type: { routine_based: 0, free_style: 1 }

  STATUSES = %w[in_progress paused completed abandoned].freeze
  RATING_RANGE = (1..10).freeze

  validates :status, inclusion: { in: STATUSES }
  validates :workout_rating, inclusion: { in: RATING_RANGE }, allow_nil: true
  validates :routine, presence: true, if: :routine_based?
  validates :name, presence: true, if: :free_style?
  validate :validate_one_active_workout_per_user, on: :create, unless: :skip_active_workout_validation

  before_validation :set_default_status, on: :create
  before_validation :set_default_workout_type, on: :create
  before_save :update_duration, if: :completed_at_changed?
  after_create :copy_routine_exercises, if: :routine_based?

  scope :recent, -> { order(created_at: :desc) }
  scope :this_week, -> { where(created_at: Time.current.beginning_of_week..Time.current.end_of_week) }
  scope :this_month, -> { where(created_at: Time.current.beginning_of_month..Time.current.end_of_month) }
  scope :with_routine, -> { routine_based.joins(:routine) }
  scope :free_workouts, -> { free_style }
  scope :active, -> { where(status: ['in_progress', 'paused']) }
  scope :completed, -> { where(status: 'completed') }
  
  # Rating-based scopes for analytics
  scope :rated, -> { where.not(workout_rating: nil) }
  scope :highly_rated, -> { where(workout_rating: 7..10) }
  scope :poorly_rated, -> { where(workout_rating: 1..3) }
  scope :average_rated, -> { where(workout_rating: 4..6) }

  def pause!(reason)
    return false unless active? && !paused?
    
    transaction do
      pauses.create!(paused_at: Time.current, reason: reason)
      update!(status: 'paused')
    end
  end

  def resume!
    return false unless paused?
    
    transaction do
      if current_pause = pauses.find_by(resumed_at: nil)
        current_pause.update!(
          resumed_at: Time.current,
          duration_seconds: (Time.current - current_pause.paused_at).to_i
        )
      end
      update!(status: 'in_progress')
    end
  end

  def complete!
    return false unless active?
    
    transaction do
      resume! if paused?
      
      exercises.each(&:finalize!)
      calculate_totals
      
      update!(
        status: 'completed',
        completed_at: Time.current,
        followed_routine: exercises.all?(&:completed_as_prescribed?)
      )
      
      # Check for personal records after workout completion
      check_personal_records!
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  rescue ActiveRecord::RecordNotSaved => e
    errors.add(:base, "Could not save workout completion")
    false
  rescue => e
    Rails.logger.error "Unexpected error completing workout: #{e.message}\n#{e.backtrace.join("\n")}"
    errors.add(:base, "An unexpected error occurred while completing the workout")
    false
  end

  def abandon!
    return false if completed?
    update!(status: 'abandoned', completed_at: Time.current)
  end

  def total_pause_duration
    pauses.sum { |pause| pause.duration_seconds || 0 }
  end

  def actual_duration
    return 0 unless started_at
    return 0 if started_at > Time.current # Validación adicional
    
    end_time = completed_at || Time.current
    base_duration = [end_time - started_at, 0].max # Evitar negativos
    [base_duration - total_pause_duration, 0].max
  end

  def display_name
    if routine_based? && routine.present?
      routine.name
    elsif free_style? && name.present?
      name
    else
      "Untitled Workout"
    end
  end

  def has_exercises?
    exercises.exists?
  end

  # Workout rating interpretation helpers
  def rating_description
    return 'Not rated' unless workout_rating

    case workout_rating
    when 1..3
      'Poor workout'
    when 4..6
      'Average workout'
    when 7..8
      'Good workout'
    when 9..10
      'Excellent workout'
    else
      'Invalid rating'
    end
  end

  def positive_workout?
    workout_rating && workout_rating >= 7
  end

  def negative_workout?
    workout_rating && workout_rating <= 3
  end

  private

  def validate_one_active_workout_per_user
    return unless user.present?
    
    if user.workouts.active.exists?
      errors.add(:base, 'You already have an active workout')
    end
  end

  def set_default_status
    self.status ||= 'in_progress'
    self.started_at ||= Time.current
  end

  def set_default_workout_type
    if routine_id.present?
      self.workout_type ||= 'routine_based'
    else
      self.workout_type ||= 'free_style'
    end
  end

  def update_duration
    self.total_duration_seconds = actual_duration.to_i if completed_at
  end

  def copy_routine_exercises
    routine.routine_exercises.ordered.each do |routine_exercise|
      exercises.create!(
        exercise: routine_exercise.exercise,
        routine_exercise: routine_exercise,
        order: routine_exercise.order,
        group_type: routine_exercise.group_type || 'regular',
        group_order: routine_exercise.group_order,
        target_sets: routine_exercise.sets,
        target_reps: routine_exercise.reps,
        suggested_weight: routine_exercise.weight
      )
    end
  end

  def calculate_totals
    self.total_volume = exercises.sum(&:total_volume)
    self.total_sets_completed = exercises.sum(&:completed_sets_count)
    self.total_exercises_completed = exercises.count(&:completed?)
    self.average_rpe = exercises.map(&:average_rpe).compact.sum / [exercises.count, 1].max
  end
  
  def check_personal_records!
    # Check PRs for all completed normal sets in this workout
    # Preload associations to avoid N+1 queries
    exercises.includes(sets: :exercise).each do |workout_exercise|
      workout_exercise.sets.completed.normal.each do |workout_set|
        workout_set.check_for_personal_records
      end
    end
  end
end 