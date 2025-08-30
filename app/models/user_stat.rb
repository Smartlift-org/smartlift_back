class UserStat < ApplicationRecord
  belongs_to :user

  EXPERIENCE_LEVELS = %w[beginner intermediate advanced].freeze
  ACTIVITY_LEVELS = %w[sedentary moderate active].freeze

  validates :experience_level, inclusion: { in: EXPERIENCE_LEVELS }
  validates :activity_level, inclusion: { in: ACTIVITY_LEVELS }
  validates :physical_limitations, presence: true
end 