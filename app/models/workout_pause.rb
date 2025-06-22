class WorkoutPause < ApplicationRecord
  belongs_to :workout

  validates :paused_at, presence: true
  validates :reason, presence: true
  validates :duration_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :resumed_at_after_paused_at, if: :resumed_at?

  before_save :calculate_duration, if: :resumed_at_changed?

  scope :active, -> { where(resumed_at: nil) }
  scope :completed, -> { where.not(resumed_at: nil) }

  def duration
    return 0 unless paused_at
    (resumed_at || Time.current) - paused_at
  end

  def active?
    resumed_at.nil?
  end

  def completed?
    resumed_at.present?
  end

  private

  def resumed_at_after_paused_at
    if resumed_at <= paused_at
      errors.add(:resumed_at, "must be after paused_at")
    end
  end

  def calculate_duration
    self.duration_seconds = (resumed_at - paused_at).to_i if resumed_at && paused_at
  end
end 