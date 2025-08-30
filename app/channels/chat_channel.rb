class ChatChannel < ApplicationCable::Channel
  def subscribed
    conversation = find_conversation
    return reject unless conversation
    
    stream_for conversation
    Rails.logger.info "User #{current_user.id} subscribed to conversation #{conversation.id}"
  end
  
  def unsubscribed
    Rails.logger.info "User #{current_user.id} unsubscribed from chat"
  end
  
  def typing(data)
    conversation = find_conversation
    return unless conversation
    
    ChatChannel.broadcast_to(
      conversation,
      {
        type: 'typing',
        user: UserBasicSerializer.new(current_user).as_json,
        timestamp: Time.current.iso8601
      }
    )
  end
  
  def stop_typing(data)
    conversation = find_conversation
    return unless conversation
    
    ChatChannel.broadcast_to(
      conversation,
      {
        type: 'stop_typing',
        user: UserBasicSerializer.new(current_user).as_json,
        timestamp: Time.current.iso8601
      }
    )
  end
  
  private
  
  def find_conversation
    conversation_id = params[:conversation_id]
    return nil unless conversation_id
    
    conversation = current_user.conversations.find_by(id: conversation_id)
    unless conversation
      Rails.logger.error "User #{current_user.id} tried to access conversation #{conversation_id} without permission"
    end
    
    conversation
  end
end
