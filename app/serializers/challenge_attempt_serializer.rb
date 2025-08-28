class ChallengeAttemptSerializer < ActiveModel::Serializer
  attributes :id, :challenge_id, :user_id, :completion_time_seconds, :started_at, 
             :completed_at, :status, :is_best_attempt, :exercise_times, 
             :formatted_completion_time, :total_exercise_time
  
  belongs_to :user, serializer: UserBasicSerializer

  def formatted_completion_time
    object.formatted_completion_time
  end

  def total_exercise_time
    object.total_exercise_time
  end
end
