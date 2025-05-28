class CoachUser < ApplicationRecord
  belongs_to :coach, class_name: 'User'
  belongs_to :user, class_name: 'User'
  
  validates :coach_id, uniqueness: { scope: :user_id, message: "ya está asignado a este usuario" }
  validate :coach_must_be_coach
  validate :user_must_be_user
  
  private
  
  def coach_must_be_coach
    unless coach.coach?
      errors.add(:coach, "debe tener rol de coach")
    end
  end
  
  def user_must_be_user
    unless user.user?
      errors.add(:user, "debe tener rol de usuario")
    end
  end
end 