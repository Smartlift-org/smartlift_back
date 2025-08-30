class ChallengeExercise < ApplicationRecord
  belongs_to :challenge
  belongs_to :exercise

  validates :sets, :reps, presence: true, numericality: { greater_than: 0 }
  validates :rest_time_seconds, numericality: { greater_than_or_equal_to: 0 }
  validates :order_index, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :order_index, uniqueness: { scope: :challenge_id }

  scope :ordered, -> { order(:order_index) }
end
