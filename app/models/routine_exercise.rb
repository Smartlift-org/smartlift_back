class RoutineExercise < ApplicationRecord
  belongs_to :routine
  belongs_to :exercise

  validates :sets, numericality: { greater_than: 0 }
  validates :reps, numericality: { greater_than: 0 }
  validates :rest_time, numericality: { greater_than_or_equal_to: 0 }
  validates :order, numericality: { greater_than: 0 }
end 