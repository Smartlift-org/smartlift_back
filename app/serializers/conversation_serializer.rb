class ConversationSerializer < ActiveModel::Serializer
  attributes :id, :status, :last_message_at, :created_at, :unread_count
  
  belongs_to :user, serializer: UserBasicSerializer
  belongs_to :coach, serializer: UserBasicSerializer
  has_one :last_message, serializer: MessageSerializer
  
  def last_message
    object.last_message
  end
  
  def last_message_at
    object.last_message_at&.iso8601
  end
  
  def created_at
    object.created_at.iso8601
  end
  
  def unread_count
    # El contexto del usuario actual se pasa desde el controlador
    current_user = instance_options[:current_user]
    return 0 unless current_user
    
    object.unread_count_for(current_user)
  end
end
