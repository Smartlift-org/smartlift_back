class ChallengeSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :difficulty_level, :start_date, :end_date, 
             :is_active, :estimated_duration_minutes, :coach_id, :participants_count,
             :total_attempts, :completed_attempts, :is_active_now
  
  has_many :challenge_exercises, serializer: ChallengeExerciseSerializer
  belongs_to :coach, serializer: UserBasicSerializer

  def participants_count
    object.participants_count
  end

  def total_attempts
    object.total_attempts
  end

  def completed_attempts
    object.completed_attempts
  end

  def is_active_now
    object.is_active_now?
  end
end
