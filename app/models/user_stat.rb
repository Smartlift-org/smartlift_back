class UserStat < ApplicationRecord
  belongs_to :user

  EXPERIENCE_LEVELS = %w[beginner intermediate advanced].freeze
  ACTIVITY_LEVELS = %w[sedentary moderate active].freeze

  validates :height, presence: true
  validates :weight, presence: true
  validates :age, presence: true
  validates :gender, presence: true
  validates :fitness_goal, presence: true
  validates :experience_level, presence: true, inclusion: { in: EXPERIENCE_LEVELS }
  validates :available_days, presence: true
  validates :equipment_available, presence: true
  validates :activity_level, presence: true, inclusion: { in: ACTIVITY_LEVELS }
  validates :physical_limitations, presence: true
end
