class PushNotificationJob < ApplicationJob
  queue_as :default
  
  def perform(message)
    return unless message.is_a?(Message)
    
    conversation = message.conversation
    recipient = message.recipient
    
    return unless recipient
    return unless recipient.expo_push_token.present?
    return unless recipient.push_notifications_enabled?
    
    # No enviar notificación si el mensaje es del mismo usuario
    return if message.sender_id == recipient.id
    
    begin
      ExpoNotificationService.new.send_notification(
        token: recipient.expo_push_token,
        title: "Nuevo mensaje de #{message.sender.first_name}",
        body: truncate_message(message.content),
        data: {
          type: 'chat_message',
          conversation_id: conversation.id,
          message_id: message.id,
          sender_id: message.sender_id,
          sender_name: "#{message.sender.first_name} #{message.sender.last_name}"
        }
      )
      
      Rails.logger.info "Push notification sent to user #{recipient.id} for message #{message.id}"
    rescue => e
      Rails.logger.error "Error sending push notification: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
  
  private
  
  def truncate_message(content)
    return content if content.length <= 100
    "#{content[0..97]}..."
  end
end
