class Conversation < ApplicationRecord
  belongs_to :user
  belongs_to :coach, class_name: 'User'
  has_many :messages, dependent: :destroy
  
  validates :user_id, uniqueness: { scope: :coach_id, message: "Ya existe una conversación entre este usuario y entrenador" }
  validates :status, inclusion: { in: %w[active archived], message: "Estado debe ser 'active' o 'archived'" }
  validates :coach, presence: true
  validates :user, presence: true
  
  # Validar que el coach tenga rol de coach y el user tenga rol de user
  validate :coach_must_be_coach
  validate :user_must_be_user_or_assigned_to_coach
  
  scope :active, -> { where(status: 'active') }
  scope :archived, -> { where(status: 'archived') }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :for_coach, ->(coach_id) { where(coach_id: coach_id) }
  scope :recent, -> { order(last_message_at: :desc, updated_at: :desc) }
  
  def last_message
    messages.order(:created_at).last
  end
  
  def unread_count_for(user)
    return 0 unless user
    
    messages.where('sender_id != ? AND read_at IS NULL', user.id).count
  end
  
  def mark_messages_as_read_for(user)
    return false unless user
    
    messages.where('sender_id != ? AND read_at IS NULL', user.id)
            .update_all(read_at: Time.current)
  end
  
  def other_participant(current_user)
    return coach if current_user.id == user_id
    return user if current_user.id == coach_id
    nil
  end
  
  def participant?(user)
    user_id == user.id || coach_id == user.id
  end
  
  private
  
  def coach_must_be_coach
    return unless coach
    
    unless coach.coach?
      errors.add(:coach, "debe tener rol de entrenador")
    end
  end
  
  def user_must_be_user_or_assigned_to_coach
    return unless user && coach
    
    unless user.user?
      errors.add(:user, "debe tener rol de usuario")
      return
    end
    
    # Verificar que el usuario esté asignado al entrenador
    unless coach.users.include?(user)
      errors.add(:user, "debe estar asignado al entrenador")
    end
  end
end
