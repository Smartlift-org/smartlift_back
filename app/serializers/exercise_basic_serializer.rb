class ExerciseBasicSerializer < ActiveModel::Serializer
  attributes :id, :name, :primary_muscles, :difficulty_level, :video_url
end
