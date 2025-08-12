class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_conversation, only: [:show, :mark_as_read]
  
  def index
    conversations = current_user.conversations
                                .includes(:user, :coach, :messages)
                                .recent
                                .page(params[:page])
                                .per(20)
    
    render json: conversations, 
           each_serializer: ConversationSerializer,
           current_user: current_user
  end
  
  def show
    messages = @conversation.messages
                           .includes(:sender)
                           .recent
                           .page(params[:page])
                           .per(50)
    
    render json: {
      conversation: ConversationSerializer.new(@conversation, current_user: current_user),
      messages: messages.map { |m| MessageSerializer.new(m) },
      pagination: {
        current_page: messages.current_page,
        total_pages: messages.total_pages,
        total_count: messages.total_count
      }
    }
  end
  
  def create
    # Determinar coach y user basado en el rol del usuario actual
    if current_user.user?
      coach = User.coach.find(params[:coach_id])
      user = current_user
    elsif current_user.coach?
      user = User.user.find(params[:user_id])
      coach = current_user
    else
      render json: { error: "Solo usuarios y entrenadores pueden crear conversaciones" }, 
             status: :forbidden
      return
    end
    
    # Verificar que el usuario puede chatear con el entrenador
    unless current_user.can_chat_with?(current_user.user? ? coach : user)
      render json: { error: "No tienes permisos para chatear con este usuario" }, 
             status: :forbidden
      return
    end
    
    conversation = Conversation.find_or_create_by(user: user, coach: coach)
    
    if conversation.persisted?
      render json: conversation, 
             serializer: ConversationSerializer,
             current_user: current_user,
             status: :created
    else
      render json: { errors: conversation.errors.full_messages }, 
             status: :unprocessable_entity
    end
  end
  
  def mark_as_read
    @conversation.mark_messages_as_read_for(current_user)
    head :ok
  end
  
  private
  
  def find_conversation
    @conversation = current_user.conversations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Conversación no encontrada" }, status: :not_found
  end
end
