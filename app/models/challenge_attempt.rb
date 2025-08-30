class ChallengeAttempt < ApplicationRecord
  belongs_to :challenge
  belongs_to :user

  enum status: { in_progress: 0, completed: 1, abandoned: 2 }

  validates :completion_time_seconds, numericality: { greater_than: 0 }, if: :completed?
  validate :user_belongs_to_coach
  validate :challenge_is_active, on: :create
  validate :only_one_active_attempt, on: :create

  after_update :update_best_attempt, if: :saved_change_to_completion_time_seconds?

  scope :best_attempts, -> { where(is_best_attempt: true) }
  scope :for_leaderboard, -> { where(status: 'completed', is_best_attempt: true) }

  def formatted_completion_time
    return nil unless completion_time_seconds
    
    minutes = completion_time_seconds / 60
    seconds = completion_time_seconds % 60
    "#{minutes}:#{seconds.to_s.rjust(2, '0')}"
  end

  def total_exercise_time
    return 0 unless exercise_times.present?
    exercise_times.values.sum
  end

  private

  def user_belongs_to_coach
    return unless user && challenge&.coach
    unless user.coaches.include?(challenge.coach)
      errors.add(:user, 'debe ser usuario del entrenador que creó el desafío')
    end
  end

  def challenge_is_active
    return unless challenge
    unless challenge.is_active_now?
      errors.add(:challenge, 'no está activo o ha expirado')
    end
  end

  def only_one_active_attempt
    return unless user && challenge
    if challenge.challenge_attempts.where(user: user, status: 'in_progress').exists?
      errors.add(:base, 'Ya tienes un intento activo para este desafío')
    end
  end

  def update_best_attempt
    return unless completed? && completion_time_seconds

    # Marcar otros intentos como no-mejores
    ChallengeAttempt.where(challenge: challenge, user: user, is_best_attempt: true)
                   .where.not(id: id)
                   .update_all(is_best_attempt: false)

    # Verificar si este es el mejor tiempo
    best_time = ChallengeAttempt.where(challenge: challenge, user: user, status: 'completed')
                               .minimum(:completion_time_seconds)
    
    update_column(:is_best_attempt, completion_time_seconds == best_time)
  end
end
