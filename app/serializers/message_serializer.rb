class MessageSerializer < ActiveModel::Serializer
  attributes :id, :content, :message_type, :read_at, :created_at, :formatted_created_at
  
  belongs_to :sender, serializer: UserBasicSerializer
  
  def created_at
    object.created_at.iso8601
  end
  
  def formatted_created_at
    object.formatted_created_at
  end
  
  def read_at
    object.read_at&.iso8601
  end
end
