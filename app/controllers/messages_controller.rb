class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_conversation
  
  def create
    message = @conversation.messages.build(message_params)
    message.sender = current_user
    
    if message.save
      render json: message, serializer: MessageSerializer, status: :created
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def mark_as_read
    message = @conversation.messages.find(params[:id])
    
    # Solo el destinatario puede marcar como leído
    if message.recipient == current_user
      message.mark_as_read!
      head :ok
    else
      render json: { error: "No tienes permisos para marcar este mensaje como leído" }, 
             status: :forbidden
    end
  end
  
  private
  
  def find_conversation
    @conversation = current_user.conversations.find(params[:conversation_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Conversación no encontrada" }, status: :not_found
  end
  
  def message_params
    params.require(:message).permit(:content, :message_type, :metadata)
  end
end
