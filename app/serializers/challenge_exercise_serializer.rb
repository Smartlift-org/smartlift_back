class ChallengeExerciseSerializer < ActiveModel::Serializer
  attributes :id, :exercise_id, :sets, :reps, :rest_time_seconds, :order_index, :notes
  
  belongs_to :exercise, serializer: ExerciseBasicSerializer
end
