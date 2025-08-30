class RoutineSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :difficulty, :duration, :source_type,
             :validation_status, :ai_generated, :validated_by_id, :validated_at,
             :validation_notes, :ai_prompt_data, :created_at, :updated_at,
             :routine_exercises

  belongs_to :user, serializer: UserBasicSerializer
  belongs_to :validated_by, serializer: UserBasicSerializer
  has_many :routine_exercises, serializer: RoutineExerciseSerializer
  
  def routine_exercises
    object.routine_exercises.includes(:exercise).order(:order)
  end
end
