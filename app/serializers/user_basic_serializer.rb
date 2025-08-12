class UserBasicSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :profile_picture_url, :full_name
  
  def profile_picture_url
    object.profile_picture_url_with_fallback || "https://via.placeholder.com/40"
  end
  
  def full_name
    "#{object.first_name} #{object.last_name}"
  end
end
