class UserStat < ApplicationRecord
  belongs_to :user

  EXPERIENCE_LEVELS = %w[beginner intermediate advanced].freeze
  ACTIVITY_LEVELS = %w[sedentary moderate active].freeze
  GENDERS = %w[male female other].freeze

  validates :experience_level, inclusion: { in: EXPERIENCE_LEVELS }
  validates :activity_level, inclusion: { in: ACTIVITY_LEVELS }
  validates :gender, inclusion: { in: GENDERS }, allow_blank: true
  validates :physical_limitations, presence: true
end
