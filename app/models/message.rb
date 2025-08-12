class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: 'User'
  
  validates :content, presence: { message: "El contenido del mensaje no puede estar vacío" }
  validates :message_type, inclusion: { in: %w[text image file], message: "Tipo de mensaje debe ser 'text', 'image' o 'file'" }
  validates :sender, presence: true
  validates :conversation, presence: true
  
  # Validar que el sender sea participante de la conversación
  validate :sender_must_be_participant
  
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(:created_at) }
  scope :for_conversation, ->(conversation_id) { where(conversation_id: conversation_id) }
  scope :from_sender, ->(sender_id) { where(sender_id: sender_id) }
  
  after_create :update_conversation_timestamp
  after_create :broadcast_message
  after_create :send_push_notification
  
  def read?
    read_at.present?
  end
  
  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end
  
  def recipient
    return conversation.coach if sender_id == conversation.user_id
    return conversation.user if sender_id == conversation.coach_id
    nil
  end
  
  def formatted_created_at
    created_at.strftime('%d/%m/%Y %H:%M')
  end
  
  private
  
  def sender_must_be_participant
    return unless sender && conversation
    
    unless conversation.participant?(sender)
      errors.add(:sender, "debe ser participante de la conversación")
    end
  end
  
  def update_conversation_timestamp
    conversation.update_column(:last_message_at, created_at)
  end
  
  def broadcast_message
    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type: 'new_message',
        message: MessageSerializer.new(self).as_json
      }
    )
  rescue => e
    Rails.logger.error "Error broadcasting message: #{e.message}"
  end
  
  def send_push_notification
    PushNotificationJob.perform_later(self)
  rescue => e
    Rails.logger.error "Error queuing push notification: #{e.message}"
  end
end
