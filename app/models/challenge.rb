class Challenge < ApplicationRecord
  belongs_to :coach, class_name: 'User'
  has_many :challenge_exercises, -> { order(:order_index) }, dependent: :destroy
  has_many :exercises, through: :challenge_exercises
  has_many :challenge_attempts, dependent: :destroy
  has_many :participants, -> { distinct }, through: :challenge_attempts, source: :user

  accepts_nested_attributes_for :challenge_exercises, allow_destroy: true

  validates :name, presence: true, length: { maximum: 100 }
  validates :difficulty_level, inclusion: { in: 1..5 }
  validates :start_date, :end_date, presence: true
  validate :end_date_after_start_date
  validate :coach_must_be_coach_role

  scope :active, -> { where(is_active: true) }
  scope :current_week, -> { where('start_date <= ? AND end_date >= ?', Time.current, Time.current) }
  scope :by_coach, ->(coach_id) { where(coach_id: coach_id) }

  def is_active_now?
    is_active && Time.current.between?(start_date, end_date)
  end

  def leaderboard
    challenge_attempts
      .includes(:user)
      .where(status: 'completed', is_best_attempt: true)
      .order(:completion_time_seconds)
      .limit(50)
  end

  def user_best_attempt(user)
    challenge_attempts.where(user: user, is_best_attempt: true).first
  end

  def participants_count
    participants.count
  end

  def total_attempts
    challenge_attempts.count
  end

  def completed_attempts
    challenge_attempts.where(status: 'completed').count
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, 'debe ser posterior a la fecha de inicio') if end_date <= start_date
  end

  def coach_must_be_coach_role
    errors.add(:coach, 'debe tener rol de entrenador') unless coach&.coach?
  end
end
