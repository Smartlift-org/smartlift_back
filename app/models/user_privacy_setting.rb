class UserPrivacySetting < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :show_name, inclusion: { in: [true, false] }
  validates :show_profile_picture, inclusion: { in: [true, false] }
  validates :show_workout_count, inclusion: { in: [true, false] }
  validates :show_join_date, inclusion: { in: [true, false] }
  validates :show_personal_records, inclusion: { in: [true, false] }
  validates :show_favorite_exercises, inclusion: { in: [true, false] }
  validates :is_profile_public, inclusion: { in: [true, false] }

  scope :public_profiles, -> { where(is_profile_public: true) }

  # Helper methods for checking visibility
  def show_field?(field_name)
    case field_name.to_sym
    when :name
      show_name?
    when :profile_picture
      show_profile_picture?
    when :workout_count
      show_workout_count?
    when :join_date
      show_join_date?
    when :personal_records
      show_personal_records?
    when :favorite_exercises
      show_favorite_exercises?
    else
      false
    end
  end

  # Create default privacy settings for new users
  def self.create_default_for_user(user)
    create!(
      user: user,
      show_name: true,
      show_profile_picture: true,
      show_workout_count: true,
      show_join_date: false,
      show_personal_records: false,
      show_favorite_exercises: false,
      is_profile_public: false
    )
  end
end
